
var Module;

if (typeof Module === 'undefined') Module = eval('(function() { try { return Module || {} } catch(e) { return {} } })()');

if (!Module.expectedDataFileDownloads) {
  Module.expectedDataFileDownloads = 0;
  Module.finishedDataFileDownloads = 0;
}
Module.expectedDataFileDownloads++;
(function() {
 var loadPackage = function(metadata) {

  var PACKAGE_PATH;
  if (typeof window === 'object') {
    PACKAGE_PATH = window['encodeURIComponent'](window.location.pathname.toString().substring(0, window.location.pathname.toString().lastIndexOf('/')) + '/');
  } else if (typeof location !== 'undefined') {
      // worker
      PACKAGE_PATH = encodeURIComponent(location.pathname.toString().substring(0, location.pathname.toString().lastIndexOf('/')) + '/');
    } else {
      throw 'using preloaded data can only be done on a web page or in a web worker';
    }
    var PACKAGE_NAME = 'game.data';
    var REMOTE_PACKAGE_BASE = 'game.data';
    if (typeof Module['locateFilePackage'] === 'function' && !Module['locateFile']) {
      Module['locateFile'] = Module['locateFilePackage'];
      Module.printErr('warning: you defined Module.locateFilePackage, that has been renamed to Module.locateFile (using your locateFilePackage for now)');
    }
    var REMOTE_PACKAGE_NAME = typeof Module['locateFile'] === 'function' ?
    Module['locateFile'](REMOTE_PACKAGE_BASE) :
    ((Module['filePackagePrefixURL'] || '') + REMOTE_PACKAGE_BASE);

    var REMOTE_PACKAGE_SIZE = metadata.remote_package_size;
    var PACKAGE_UUID = metadata.package_uuid;

    function fetchRemotePackage(packageName, packageSize, callback, errback) {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', packageName, true);
      xhr.responseType = 'arraybuffer';
      xhr.onprogress = function(event) {
        var url = packageName;
        var size = packageSize;
        if (event.total) size = event.total;
        if (event.loaded) {
          if (!xhr.addedTotal) {
            xhr.addedTotal = true;
            if (!Module.dataFileDownloads) Module.dataFileDownloads = {};
            Module.dataFileDownloads[url] = {
              loaded: event.loaded,
              total: size
            };
          } else {
            Module.dataFileDownloads[url].loaded = event.loaded;
          }
          var total = 0;
          var loaded = 0;
          var num = 0;
          for (var download in Module.dataFileDownloads) {
            var data = Module.dataFileDownloads[download];
            total += data.total;
            loaded += data.loaded;
            num++;
          }
          total = Math.ceil(total * Module.expectedDataFileDownloads/num);
          if (Module['setStatus']) Module['setStatus']('Downloading data... (' + loaded + '/' + total + ')');
        } else if (!Module.dataFileDownloads) {
          if (Module['setStatus']) Module['setStatus']('Downloading data...');
        }
      };
      xhr.onerror = function(event) {
        throw new Error("NetworkError for: " + packageName);
      }
      xhr.onload = function(event) {
        if (xhr.status == 200 || xhr.status == 304 || xhr.status == 206 || (xhr.status == 0 && xhr.response)) { // file URLs can return 0
          var packageData = xhr.response;
          callback(packageData);
        } else {
          throw new Error(xhr.statusText + " : " + xhr.responseURL);
        }
      };
      xhr.send(null);
    };

    function handleError(error) {
      console.error('package error:', error);
    };

    function runWithFS() {

      function assert(check, msg) {
        if (!check) throw msg + new Error().stack;
      }
      Module['FS_createPath']('/', 'data', true, true);
      Module['FS_createPath']('/data', 'audio', true, true);
      Module['FS_createPath']('/data', 'textures', true, true);
      Module['FS_createPath']('/data', 'tilesmaps', true, true);

      function DataRequest(start, end, crunched, audio) {
        this.start = start;
        this.end = end;
        this.crunched = crunched;
        this.audio = audio;
      }
      DataRequest.prototype = {
        requests: {},
        open: function(mode, name) {
          this.name = name;
          this.requests[name] = this;
          Module['addRunDependency']('fp ' + this.name);
        },
        send: function() {},
        onload: function() {
          var byteArray = this.byteArray.subarray(this.start, this.end);

          this.finish(byteArray);

        },
        finish: function(byteArray) {
          var that = this;

        Module['FS_createDataFile'](this.name, null, byteArray, true, true, true); // canOwn this data in the filesystem, it is a slide into the heap that will never change
        Module['removeRunDependency']('fp ' + that.name);

        this.requests[this.name] = null;
      }
    };

    var files = metadata.files;
    for (i = 0; i < files.length; ++i) {
      new DataRequest(files[i].start, files[i].end, files[i].crunched, files[i].audio).open('GET', files[i].filename);
    }


    var indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
    var IDB_RO = "readonly";
    var IDB_RW = "readwrite";
    var DB_NAME = "EM_PRELOAD_CACHE";
    var DB_VERSION = 1;
    var METADATA_STORE_NAME = 'METADATA';
    var PACKAGE_STORE_NAME = 'PACKAGES';
    function openDatabase(callback, errback) {
      try {
        var openRequest = indexedDB.open(DB_NAME, DB_VERSION);
      } catch (e) {
        return errback(e);
      }
      openRequest.onupgradeneeded = function(event) {
        var db = event.target.result;

        if(db.objectStoreNames.contains(PACKAGE_STORE_NAME)) {
          db.deleteObjectStore(PACKAGE_STORE_NAME);
        }
        var packages = db.createObjectStore(PACKAGE_STORE_NAME);

        if(db.objectStoreNames.contains(METADATA_STORE_NAME)) {
          db.deleteObjectStore(METADATA_STORE_NAME);
        }
        var metadata = db.createObjectStore(METADATA_STORE_NAME);
      };
      openRequest.onsuccess = function(event) {
        var db = event.target.result;
        callback(db);
      };
      openRequest.onerror = function(error) {
        errback(error);
      };
    };

    /* Check if there's a cached package, and if so whether it's the latest available */
    function checkCachedPackage(db, packageName, callback, errback) {
      var transaction = db.transaction([METADATA_STORE_NAME], IDB_RO);
      var metadata = transaction.objectStore(METADATA_STORE_NAME);

      var getRequest = metadata.get("metadata/" + packageName);
      getRequest.onsuccess = function(event) {
        var result = event.target.result;
        if (!result) {
          return callback(false);
        } else {
          return callback(PACKAGE_UUID === result.uuid);
        }
      };
      getRequest.onerror = function(error) {
        errback(error);
      };
    };

    function fetchCachedPackage(db, packageName, callback, errback) {
      var transaction = db.transaction([PACKAGE_STORE_NAME], IDB_RO);
      var packages = transaction.objectStore(PACKAGE_STORE_NAME);

      var getRequest = packages.get("package/" + packageName);
      getRequest.onsuccess = function(event) {
        var result = event.target.result;
        callback(result);
      };
      getRequest.onerror = function(error) {
        errback(error);
      };
    };

    function cacheRemotePackage(db, packageName, packageData, packageMeta, callback, errback) {
      var transaction_packages = db.transaction([PACKAGE_STORE_NAME], IDB_RW);
      var packages = transaction_packages.objectStore(PACKAGE_STORE_NAME);

      var putPackageRequest = packages.put(packageData, "package/" + packageName);
      putPackageRequest.onsuccess = function(event) {
        var transaction_metadata = db.transaction([METADATA_STORE_NAME], IDB_RW);
        var metadata = transaction_metadata.objectStore(METADATA_STORE_NAME);
        var putMetadataRequest = metadata.put(packageMeta, "metadata/" + packageName);
        putMetadataRequest.onsuccess = function(event) {
          callback(packageData);
        };
        putMetadataRequest.onerror = function(error) {
          errback(error);
        };
      };
      putPackageRequest.onerror = function(error) {
        errback(error);
      };
    };

    function processPackageData(arrayBuffer) {
      Module.finishedDataFileDownloads++;
      assert(arrayBuffer, 'Loading data file failed.');
      assert(arrayBuffer instanceof ArrayBuffer, 'bad input to processPackageData');
      var byteArray = new Uint8Array(arrayBuffer);
      var curr;

        // copy the entire loaded file into a spot in the heap. Files will refer to slices in that. They cannot be freed though
        // (we may be allocating before malloc is ready, during startup).
        if (Module['SPLIT_MEMORY']) Module.printErr('warning: you should run the file packager with --no-heap-copy when SPLIT_MEMORY is used, otherwise copying into the heap may fail due to the splitting');
        var ptr = Module['getMemory'](byteArray.length);
        Module['HEAPU8'].set(byteArray, ptr);
        DataRequest.prototype.byteArray = Module['HEAPU8'].subarray(ptr, ptr+byteArray.length);

        var files = metadata.files;
        for (i = 0; i < files.length; ++i) {
          DataRequest.prototype.requests[files[i].filename].onload();
        }
        Module['removeRunDependency']('datafile_game.data');

      };
      Module['addRunDependency']('datafile_game.data');

      if (!Module.preloadResults) Module.preloadResults = {};

      function preloadFallback(error) {
        console.error(error);
        console.error('falling back to default preload behavior');
        fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE, processPackageData, handleError);
      };

      openDatabase(
        function(db) {
          checkCachedPackage(db, PACKAGE_PATH + PACKAGE_NAME,
            function(useCached) {
              Module.preloadResults[PACKAGE_NAME] = {fromCache: useCached};
              if (useCached) {
                console.info('loading ' + PACKAGE_NAME + ' from cache');
                fetchCachedPackage(db, PACKAGE_PATH + PACKAGE_NAME, processPackageData, preloadFallback);
              } else {
                console.info('loading ' + PACKAGE_NAME + ' from remote');
                fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE,
                  function(packageData) {
                    cacheRemotePackage(db, PACKAGE_PATH + PACKAGE_NAME, packageData, {uuid:PACKAGE_UUID}, processPackageData,
                      function(error) {
                        console.error(error);
                        processPackageData(packageData);
                      });
                  }
                  , preloadFallback);
              }
            }
            , preloadFallback);
        }
        , preloadFallback);

      if (Module['setStatus']) Module['setStatus']('Downloading...');

    }
    if (Module['calledRun']) {
      runWithFS();
    } else {
      if (!Module['preRun']) Module['preRun'] = [];
      Module["preRun"].push(runWithFS); // FS is not initialized yet, wait for it
    }

  }
  loadPackage({"package_uuid":"621b925a-7aa5-4149-a043-b5ac0a765cdd","remote_package_size":13176528,"files":[{"filename":"/audio.lua","crunched":0,"start":0,"end":1433,"audio":false},{"filename":"/conf.lua","crunched":0,"start":1433,"end":1632,"audio":false},{"filename":"/countdown.lua","crunched":0,"start":1632,"end":3400,"audio":false},{"filename":"/data/audio/beat.mp3","crunched":0,"start":3400,"end":11792,"audio":true},{"filename":"/data/audio/explosion.mp3","crunched":0,"start":11792,"end":16422,"audio":true},{"filename":"/data/audio/intro_loop.mp3","crunched":0,"start":16422,"end":2108340,"audio":true},{"filename":"/data/audio/level_up_1.mp3","crunched":0,"start":2108340,"end":2140764,"audio":true},{"filename":"/data/audio/level_up_2.mp3","crunched":0,"start":2140764,"end":2173188,"audio":true},{"filename":"/data/audio/music.mp3","crunched":0,"start":2173188,"end":12907457,"audio":true},{"filename":"/data/audio/sine_beep.mp3","crunched":0,"start":12907457,"end":12931522,"audio":true},{"filename":"/data/audio/square_beep.mp3","crunched":0,"start":12931522,"end":12955587,"audio":true},{"filename":"/data/imagefont.png","crunched":0,"start":12955587,"end":12957469,"audio":false},{"filename":"/data/textures/bg_00.png","crunched":0,"start":12957469,"end":12963441,"audio":false},{"filename":"/data/textures/bg_01.png","crunched":0,"start":12963441,"end":12967546,"audio":false},{"filename":"/data/textures/bg_02.png","crunched":0,"start":12967546,"end":12971807,"audio":false},{"filename":"/data/textures/bg_03.png","crunched":0,"start":12971807,"end":12974800,"audio":false},{"filename":"/data/textures/gib00.png","crunched":0,"start":12974800,"end":12977890,"audio":false},{"filename":"/data/textures/gib00_blue.png","crunched":0,"start":12977890,"end":12980987,"audio":false},{"filename":"/data/textures/gib01.png","crunched":0,"start":12980987,"end":12984006,"audio":false},{"filename":"/data/textures/gib01_blue.png","crunched":0,"start":12984006,"end":12987025,"audio":false},{"filename":"/data/textures/gib02.png","crunched":0,"start":12987025,"end":12989989,"audio":false},{"filename":"/data/textures/gib02_blue.png","crunched":0,"start":12989989,"end":12992956,"audio":false},{"filename":"/data/textures/gib03.png","crunched":0,"start":12992956,"end":12995905,"audio":false},{"filename":"/data/textures/gib03_blue.png","crunched":0,"start":12995905,"end":12998846,"audio":false},{"filename":"/data/textures/gib04.png","crunched":0,"start":12998846,"end":13001784,"audio":false},{"filename":"/data/textures/gib04_blue.png","crunched":0,"start":13001784,"end":13004725,"audio":false},{"filename":"/data/textures/gib05.png","crunched":0,"start":13004725,"end":13007662,"audio":false},{"filename":"/data/textures/gib05_blue.png","crunched":0,"start":13007662,"end":13010598,"audio":false},{"filename":"/data/textures/heart.png","crunched":0,"start":13010598,"end":13013684,"audio":false},{"filename":"/data/textures/heart_red.png","crunched":0,"start":13013684,"end":13016770,"audio":false},{"filename":"/data/textures/menu.png","crunched":0,"start":13016770,"end":13031877,"audio":false},{"filename":"/data/textures/particle_blood.png","crunched":0,"start":13031877,"end":13032205,"audio":false},{"filename":"/data/textures/particle_heart.png","crunched":0,"start":13032205,"end":13035116,"audio":false},{"filename":"/data/textures/particle_level_up_text.png","crunched":0,"start":13035116,"end":13038134,"audio":false},{"filename":"/data/textures/particle_rainbow.png","crunched":0,"start":13038134,"end":13038729,"audio":false},{"filename":"/data/textures/particle_star.png","crunched":0,"start":13038729,"end":13041662,"audio":false},{"filename":"/data/textures/particle_trail.png","crunched":0,"start":13041662,"end":13044951,"audio":false},{"filename":"/data/textures/perso01.png","crunched":0,"start":13044951,"end":13048079,"audio":false},{"filename":"/data/textures/perso01_anim.png","crunched":0,"start":13048079,"end":13051324,"audio":false},{"filename":"/data/textures/perso02.png","crunched":0,"start":13051324,"end":13054445,"audio":false},{"filename":"/data/textures/perso02_anim.png","crunched":0,"start":13054445,"end":13057601,"audio":false},{"filename":"/data/textures/progress_container_center.png","crunched":0,"start":13057601,"end":13060422,"audio":false},{"filename":"/data/textures/progress_container_left.png","crunched":0,"start":13060422,"end":13063252,"audio":false},{"filename":"/data/textures/progress_container_right.png","crunched":0,"start":13063252,"end":13066081,"audio":false},{"filename":"/data/textures/star01.png","crunched":0,"start":13066081,"end":13071243,"audio":false},{"filename":"/data/textures/star02.png","crunched":0,"start":13071243,"end":13076500,"audio":false},{"filename":"/data/textures/star03.png","crunched":0,"start":13076500,"end":13081916,"audio":false},{"filename":"/data/textures/tiles.png","crunched":0,"start":13081916,"end":13085838,"audio":false},{"filename":"/data/tilesmaps/tiles.png","crunched":0,"start":13085838,"end":13089804,"audio":false},{"filename":"/data/tilesmaps/zone_00.lua","crunched":0,"start":13089804,"end":13134204,"audio":false},{"filename":"/data/tilesmaps/zone_00.tmx","crunched":0,"start":13134204,"end":13137768,"audio":false},{"filename":"/game.lua","crunched":0,"start":13137768,"end":13142566,"audio":false},{"filename":"/hud.lua","crunched":0,"start":13142566,"end":13144442,"audio":false},{"filename":"/level.lua","crunched":0,"start":13144442,"end":13151683,"audio":false},{"filename":"/levels.lua","crunched":0,"start":13151683,"end":13152725,"audio":false},{"filename":"/main.lua","crunched":0,"start":13152725,"end":13155120,"audio":false},{"filename":"/menu.lua","crunched":0,"start":13155120,"end":13156612,"audio":false},{"filename":"/particles.lua","crunched":0,"start":13156612,"end":13160630,"audio":false},{"filename":"/perspective.lua","crunched":0,"start":13160630,"end":13165424,"audio":false},{"filename":"/physic.lua","crunched":0,"start":13165424,"end":13167111,"audio":false},{"filename":"/player.lua","crunched":0,"start":13167111,"end":13176528,"audio":false}]});

})();
