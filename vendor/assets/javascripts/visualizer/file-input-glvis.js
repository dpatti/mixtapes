var PlayerView = (function () {
    function PlayerView(playerController) {
        this.content = $("<div>", { class: "controls audio-controls" });
        this.playerController = playerController;
    }
    PlayerView.prototype.render = function (el) {
        var _this = this;
        this.audioPlayer = document.createElement("audio");
        this.audioPlayer.setAttribute("class", "audio-player");
        this.audioPlayer.controls = true;
        this.audioPlayer.autoplay = true;
        this.playerController.getUrlObservable().subscribe(function (url) {
            _this.audioPlayer.setAttribute("src", url);
            _this.audioPlayer.play();
        });
        window.addEventListener('load', function (e) {
            _this.playerController.setPlayerSource(_this.audioPlayer);
        }, false);
        this.content.append(this.audioPlayer);
        $(el).append(this.content);
    };
    return PlayerView;
})();
var PlaylistView = (function () {
    function PlaylistView(playerController) {
        this._content = $("<div>", { class: "controls playlist" });
        this._playerController = playerController;
        this._currentTrack = -1;
    }
    PlaylistView.prototype.render = function (el) {
        var _this = this;
        this._list = $("<ol>");
        this._playerController.tracks().forEach(function (track) {
        });
        this._playerController.tracks().forEach(function (track) {
            var trackLi = $("<li>", { html: _this.createText(track) });
            trackLi.click(function (e) {
                _this._playerController.playTrack(trackLi.index());
            });
            _this._list.append(trackLi);
        });
        this._playerController.getTrackObservable()
            .doOnNext(function (__) {
            if (_this._currentTrack != -1) {
                $(_this._list.children().get(_this._currentTrack)).css("font-weight", "Normal");
            }
        })
            .subscribe(function (track) {
            $(_this._list.children().get(track)).css("font-weight", "Bold");
            _this._currentTrack = track;
        });
        this._content.append(this._list);
        $(el).append(this._content);
    };
    PlaylistView.prototype.createText = function (track) {
        return track.title + " - " + track.artist;
    };
    return PlaylistView;
})();
/// <reference path="./IUniform.ts"/>
var AudioAnalyser = (function () {
    function AudioAnalyser(context, fftSize) {
        this._analyser = context.createAnalyser();
        this.fftSize = fftSize;
        this.segmentSize = fftSize / 8.0;
        this.frequencyBuffer = new Uint8Array(this.fftSize);
        this.timeDomainBuffer = new Uint8Array(this.fftSize);
    }
    AudioAnalyser.prototype.connectSource = function (node) {
        node.connect(this._analyser);
        this._connected = true;
    };
    AudioAnalyser.prototype.connectDestination = function (dest) {
        this._analyser.connect(dest);
    };
    AudioAnalyser.prototype.getFrequencyData = function () {
        if (this._connected) {
            this._analyser.getByteFrequencyData(this.frequencyBuffer);
        }
        return this.frequencyBuffer;
    };
    AudioAnalyser.prototype.getEQSegments = function () {
        if (this.frequencyBuffer != undefined) {
            var vec = [0.0, 0.0, 0.0, 0.0];
            for (var i = 0; i < this.segmentSize * 4; i++) {
                var val = this.frequencyBuffer[i];
                vec[Math.floor(i / this.segmentSize)] += val * val / (255 - ((255 - val) * i / (this.segmentSize * 4.0)));
            }
            return new THREE.Vector4(vec[0] / (256.0 * this.segmentSize), vec[1] / (256.0 * this.segmentSize), vec[2] / (256.0 * this.segmentSize), vec[3] / (256.0 * this.segmentSize));
        }
        return new THREE.Vector4(0.0, 0.0, 0.0, 0.0);
    };
    AudioAnalyser.prototype.getTimeDomainData = function () {
        if (this._connected) {
            this._analyser.getByteTimeDomainData(this.timeDomainBuffer);
        }
        return this.timeDomainBuffer;
    };
    return AudioAnalyser;
})();
/// <reference path="../typed/rx.d.ts" />
/// <reference path="../typed/waa.d.ts" />
/// <reference path='./IUniform.ts'/>
/// <reference path="./IPropertiesProvider.ts" />
/// <reference path='./AudioAnalyser.ts'/>
/// <reference path="../typed/three.d.ts"/>
var AudioManager = (function () {
    function AudioManager(audioContext) {
        this._audioContext = audioContext;
        this._audioAnalyser = new AudioAnalyser(this._audioContext, AudioManager.FFT_SIZE);
        this._audioEventSubject = new Rx.Subject();
        this.AudioEventObservable = this._audioEventSubject.asObservable();
    }
    AudioManager.prototype.updateSourceNode = function (sourceNode, connectToDestination) {
        this._audioAnalyser.connectSource(sourceNode);
        if (connectToDestination) {
            this._audioAnalyser.connectDestination(this._audioContext.destination);
        }
    };
    Object.defineProperty(AudioManager.prototype, "context", {
        get: function () {
            return this._audioContext;
        },
        enumerable: true,
        configurable: true
    });
    AudioManager.prototype.sampleAudio = function () {
        if (this._audioAnalyser === undefined) {
            return;
        }
        var frequencyBuffer = this._audioAnalyser.getFrequencyData();
        var timeDomainBuffer = this._audioAnalyser.getTimeDomainData();
        var eqSegments = this._audioAnalyser.getEQSegments();
        this._audioEventSubject.onNext({
            frequencyBuffer: frequencyBuffer,
            timeDomainBuffer: timeDomainBuffer,
            eqSegments: eqSegments
        });
    };
    AudioManager.FFT_SIZE = 1024;
    return AudioManager;
})();
var Microphone = (function () {
    function Microphone(context) {
        this.created = false;
        this.nodeSubject = new Rx.Subject();
    }
    Microphone.prototype.onContext = function (audioContext) {
        var _this = this;
        if (this.created) {
            this.nodeSubject.onNext(this.node);
            return;
        }
        var gotStream = function (stream) {
            _this.node = audioContext.createMediaStreamSource(stream);
            _this.nodeSubject.onNext(_this.node);
        };
        if (navigator.getUserMedia) {
            navigator.getUserMedia({ audio: true, video: false }, gotStream, function (err) {
                return console.log(err);
            });
        }
        else if (navigator.webkitGetUserMedia) {
            navigator.webkitGetUserMedia({ audio: true, video: false }, gotStream, function (err) {
                return console.log(err);
            });
        }
        else if (navigator.mozGetUserMedia) {
            navigator.mozGetUserMedia({ audio: true, video: false }, gotStream, function (err) {
                return console.log(err);
            });
        }
        else {
            this.created = false;
            return (alert("Error: getUserMedia not supported!"));
        }
        this.created = true;
    };
    Microphone.prototype.nodeObservable = function () {
        return this.nodeSubject;
    };
    return Microphone;
})();
/// <reference path="../typed/soundcloud.d.ts" />
var SoundCloudLoader = (function () {
    function SoundCloudLoader() {
        this.urlSubject = new Rx.Subject();
        SC.initialize({
            client_id: SoundCloudLoader.CLIENT_ID
        });
    }
    SoundCloudLoader.prototype.getUrlObservable = function () {
        return this.urlSubject.asObservable();
    };
    SoundCloudLoader.prototype.loadStream = function (url) {
        var _this = this;
        if (!SC) {
            return; // No internet
        }
        SC.get('/resolve', { url: url, test: "two" }, function (sound) {
            if (sound.errors) {
                console.log("error: ", sound.errors);
                _this.urlSubject.onError("Invalid URL");
                return;
            }
            var url = sound.kind == 'playlist' ? sound.tracks[0].stream_url : sound.stream_url;
            _this.urlSubject.onNext(url + '?client_id=' + SoundCloudLoader.CLIENT_ID);
        });
    };
    SoundCloudLoader.CLIENT_ID = "384835fc6e109a2533f83591ae3713e9";
    return SoundCloudLoader;
})();
/// <reference path="../Models/AudioManager.ts"/>
/// <reference path="../Models/Microphone.ts"/>
/// <reference path="../Models/SoundCloudLoader.ts"/>
/// <reference path="../typed/rx.binding-lite.d.ts"/>
var PlayerController = (function () {
    function PlayerController(tracks, manager) {
        this._tracks = tracks;
        this._currentTrack = 0;
        this._manager = manager;
        this._urlSubject = new Rx.BehaviorSubject(tracks[this._currentTrack].url);
        this._currentTrackSubject = new Rx.BehaviorSubject(0);
    }
    Object.defineProperty(PlayerController.prototype, "manager", {
        get: function () { return this._manager; },
        enumerable: true,
        configurable: true
    });
    PlayerController.prototype.setPlayerSource = function (source) {
        var _this = this;
        var playerSource = this.manager.context.createMediaElementSource(source);
        this.manager.updateSourceNode(playerSource, true);
        source.onended = function (ev) { return _this.nextSong(); };
    };
    PlayerController.prototype.getUrlObservable = function () {
        return this._urlSubject.asObservable();
    };
    PlayerController.prototype.getTrackObservable = function () {
        return this._currentTrackSubject.asObservable();
    };
    PlayerController.prototype.tracks = function () {
        return this._tracks;
    };
    PlayerController.prototype.playTrack = function (track) {
        if (track < this._tracks.length) {
            this._currentTrackSubject.onNext(track);
            this._urlSubject.onNext(this._tracks[track].url);
            this._currentTrack = track;
        }
    };
    PlayerController.prototype.nextSong = function () {
        this._currentTrack++;
        this.playTrack(this._currentTrack);
    };
    return PlayerController;
})();
/// <reference path='./IPropertiesProvider.ts' />
var ConstPropertiesProvider = (function () {
    function ConstPropertiesProvider() {
        this._propertiesSubject = new Rx.Subject();
    }
    ConstPropertiesProvider.prototype.glProperties = function () {
        return this._propertiesSubject.asObservable();
    };
    ConstPropertiesProvider.prototype.updateProperties = function (properties) {
        this._propertiesSubject.onNext(properties);
    };
    return ConstPropertiesProvider;
})();
/// <reference path='../Models/ConstPropertiesProvider.ts'/>
var GLView = (function () {
    function GLView(audioManager, glController) {
        this._glController = glController;
    }
    GLView.prototype.render = function (el) {
        var _this = this;
        this._camera = new THREE.Camera();
        this._scene = new THREE.Scene();
        this._renderer = new THREE.WebGLRenderer();
        this._camera.position.z = 1;
        var sceneContainer = new THREE.Object3D();
        this._scene.add(sceneContainer);
        this._glController.MeshObservable
            .scan(new THREE.Object3D(), function (obj, meshes) {
            obj = new THREE.Object3D();
            meshes.forEach(function (mesh) { return obj.add(mesh); });
            obj.position = new THREE.Vector3(0, 0, 0);
            return obj;
        })
            .subscribe(function (obj) {
            _this._scene.remove(sceneContainer);
            sceneContainer = obj;
            _this._scene.add(sceneContainer);
        });
        el.appendChild(this._renderer.domElement);
        this.onWindowResize();
        window.addEventListener('resize', function (__) { return _this.onWindowResize(); }, false);
    };
    GLView.prototype.onWindowResize = function () {
        this._renderer.setSize(window.innerWidth, window.innerHeight);
        this._glController.onNewResolution({ width: window.innerWidth, height: window.innerHeight });
    };
    GLView.prototype.animate = function () {
        this._glController.update();
        this._renderer.render(this._scene, this._camera);
    };
    return GLView;
})();
var ShaderPlane = (function () {
    function ShaderPlane(material) {
        var geometry = new THREE.PlaneBufferGeometry(2, 2);
        this._mesh = new THREE.Mesh(geometry, material);
    }
    Object.defineProperty(ShaderPlane.prototype, "mesh", {
        get: function () {
            return this._mesh;
        },
        enumerable: true,
        configurable: true
    });
    return ShaderPlane;
})();
/// <reference path="../typed/rx.d.ts"/>
/// <reference path="../typed/three.d.ts"/>
var UniformsManager = (function () {
    function UniformsManager(propertiesProviders) {
        this._uniformsSubject = new Rx.Subject();
        this.UniformsObservable = this._uniformsSubject.asObservable();
        this._propertiesProviders = propertiesProviders;
    }
    UniformsManager.prototype.calculateUniforms = function () {
        var _this = this;
        Rx.Observable.from(this._propertiesProviders)
            .flatMap(function (provider) { return provider.glProperties(); })
            .scan({}, function (acc, properties) {
            properties.forEach(function (property) { return acc[property.name] = property; });
            return acc;
        })
            .subscribe(function (properties) { return _this._uniformsSubject.onNext(properties); });
    };
    return UniformsManager;
})();
/// <reference path="../typed/rx.d.ts"/>
/// <reference path="./ShaderPlane.ts"/>
/// <reference path="./UniformsManager.ts"/>
var PropertiesShaderPlane = (function () {
    function PropertiesShaderPlane(glProperties) {
        this._shaderSubject = new Rx.Subject();
        this._meshSubject = new Rx.Subject();
        this.MeshObservable = this._meshSubject.asObservable();
        this._uniformsManager = new UniformsManager(glProperties);
        Rx.Observable.combineLatest(this._shaderSubject, this._uniformsManager.UniformsObservable, function (shaderText, uniforms) {
            var fragText = shaderText.fragmentShader;
            Object.keys(uniforms).forEach(function (key) {
                var uniform = uniforms[key];
                var uniformType;
                switch (uniform.type) {
                    case "f":
                        uniformType = "float";
                        break;
                    case "v2":
                        uniformType = "vec2";
                        break;
                    case "v4":
                        uniformType = "vec4";
                        break;
                    case "t":
                        uniformType = "sampler2D";
                        break;
                    default:
                        console.log("Unknown shader");
                }
                fragText = "uniform " + uniformType + " " + uniform.name + ";\n" + fragText;
            });
            return new THREE.ShaderMaterial({
                uniforms: uniforms,
                fragmentShader: fragText,
                vertexShader: shaderText.vertexShader
            });
        })
            .map(function (shader) { return new ShaderPlane(shader).mesh; })
            .subscribe(this._meshSubject);
    }
    PropertiesShaderPlane.prototype.onShaderText = function (shader) {
        /* Calculate the uniforms after it's subscribed to*/
        this._shaderSubject.onNext(shader);
        this._uniformsManager.calculateUniforms();
    };
    return PropertiesShaderPlane;
})();
var ShaderText = (function () {
    function ShaderText(fragment, vertex) {
        this.fragmentShader = fragment;
        this.vertexShader = vertex;
    }
    return ShaderText;
})();
/// <reference path="../typed/rx.jquery.d.ts"/>
/// <reference path='./ShaderText.ts'/>
var ShaderLoader = (function () {
    function ShaderLoader(initialMethodsUrl, utilsUrl, shadersUrl) {
        var _this = this;
        this._shadersUrl = shadersUrl;
        this._initialMethodsUrl = shadersUrl + initialMethodsUrl;
        this._utilsUrl = shadersUrl + utilsUrl;
        this.getVertex("plane").subscribe(function (vert) { return _this._regularVert = vert; });
    }
    ShaderLoader.prototype.getShaderFromServer = function (url) {
        return Rx.Observable.zip(this.getFragment(url), this.getVertex(url), function (frag, vert) { return new ShaderText(frag, vert); });
    };
    ShaderLoader.prototype.getVertex = function (url) {
        return $.getAsObservable(this._shadersUrl + url + ".vert")
            .map(function (shader) { return shader.data; })
            .onErrorResumeNext(Rx.Observable.just(this._regularVert));
    };
    ShaderLoader.prototype.getFragment = function (url) {
        return $.getAsObservable(this._shadersUrl + url + '.frag')
            .map(function (shader) { return shader.data; })
            .combineLatest(this.utilFrag(), this.initialMethodsFrag(), function (frag, im, util) { return util.concat(im).concat(frag); });
    };
    ShaderLoader.prototype.utilFrag = function () {
        var _this = this;
        if (this._utilFrag === undefined) {
            return $.getAsObservable(this._utilsUrl)
                .map(function (shader) { return shader.data; })
                .doOnNext(function (util) { return _this._utilFrag = util; });
        }
        return Rx.Observable.just(this._utilFrag);
    };
    ShaderLoader.prototype.initialMethodsFrag = function () {
        var _this = this;
        if (this._initialMethodsFrag === undefined) {
            return $.getAsObservable(this._initialMethodsUrl)
                .map(function (shader) { return shader.data; })
                .doOnNext(function (util) { return _this._initialMethodsFrag = util; });
        }
        return Rx.Observable.just(this._initialMethodsFrag);
    };
    return ShaderLoader;
})();
var ResolutionProvider = (function () {
    function ResolutionProvider() {
        this._resolutionProperty = {
            name: "resolution",
            type: "v2",
            value: new THREE.Vector2(0, 0)
        };
    }
    ResolutionProvider.prototype.glProperties = function () {
        return Rx.Observable.just([this._resolutionProperty]);
    };
    ResolutionProvider.prototype.updateResolution = function (resolution) {
        this._resolutionProperty.value = resolution;
    };
    return ResolutionProvider;
})();
var TimeProvider = (function () {
    function TimeProvider() {
        this._startTime = Date.now();
        this._timeProperty = {
            name: "time",
            type: "f",
            value: 0.0
        };
    }
    TimeProvider.prototype.glProperties = function () {
        return Rx.Observable.just([this._timeProperty]);
    };
    TimeProvider.prototype.updateTime = function () {
        this._timeProperty.value = (this._startTime - Date.now()) / 1000.0;
    };
    return TimeProvider;
})();
var AudioUniformProvider = (function () {
    function AudioUniformProvider(audioManager) {
        var _this = this;
        this._audioTextureBuffer = new Uint8Array(AudioManager.FFT_SIZE * 4);
        this._audioManager = audioManager;
        var dataTexture = new THREE.DataTexture(this._audioTextureBuffer, AudioManager.FFT_SIZE, 1, THREE.RGBAFormat, THREE.UnsignedByteType, THREE.UVMapping, THREE.ClampToEdgeWrapping, THREE.ClampToEdgeWrapping, THREE.LinearFilter, THREE.LinearMipMapLinearFilter, 1);
        this._audioTexture = {
            name: "audioTexture",
            type: "t",
            value: dataTexture
        };
        this._eqSegments = {
            name: "eqSegments",
            type: "v4",
            value: new THREE.Vector4(0.0, 0.0, 0.0, 0.0)
        };
        this._audioManager.AudioEventObservable.subscribe(function (ae) { return _this.onAudioEvent(ae); });
    }
    AudioUniformProvider.prototype.glProperties = function () {
        return Rx.Observable.just([this._audioTexture, this._eqSegments]);
    };
    AudioUniformProvider.prototype.onAudioEvent = function (audioEvent) {
        for (var i = 0; i < audioEvent.frequencyBuffer.length; i++) {
            this._audioTextureBuffer[i * 4] = audioEvent.frequencyBuffer[i];
        }
        for (var i = 0; i < audioEvent.timeDomainBuffer.length; i++) {
            this._audioTextureBuffer[i * 4 + 1] = audioEvent.frequencyBuffer[i];
        }
        this._audioTexture.value.needsUpdate = true;
        this._eqSegments.value = audioEvent.eqSegments;
    };
    return AudioUniformProvider;
})();
var LoudnessAccumulator = (function () {
    function LoudnessAccumulator(audioManager) {
        var _this = this;
        this._accumulatedUniform = {
            name: "accumulatedLoudness",
            type: "f",
            value: 0.0
        };
        this._loudnessUniform = {
            name: "loudness",
            type: "f",
            value: 0.0
        };
        audioManager.AudioEventObservable.subscribe(function (ae) { return _this.onAudioEvent(ae); });
    }
    LoudnessAccumulator.prototype.setVolumeUniform = function (volumeUniform) {
        this._volume = volumeUniform;
    };
    LoudnessAccumulator.prototype.onAudioEvent = function (audioEvent) {
        var sum = 0.0;
        for (var i = 0; i < audioEvent.frequencyBuffer.length; i++) {
            sum += audioEvent.frequencyBuffer[i];
        }
        var volume = this._volume === undefined ? 1.0 : this._volume.value;
        var average = sum / audioEvent.frequencyBuffer.length;
        average = average / 128.0;
        this._accumulatedUniform.value += average * volume;
        this._loudnessUniform.value = average;
    };
    LoudnessAccumulator.prototype.glProperties = function () {
        return Rx.Observable.just([this._accumulatedUniform, this._loudnessUniform]);
    };
    return LoudnessAccumulator;
})();
/// <reference path='../typed/three.d.ts'/>
/// <reference path='../Models/IPropertiesProvider.ts'/>
/// <reference path='../Models/PropertiesShaderPlane.ts'/>
/// <reference path='../Models/ShaderLoader.ts'/>
/// <reference path='../Models/ResolutionProvider.ts'/>
/// <reference path='../Models/TimeProvider.ts'/>
/// <reference path='../Models/AudioUniformProvider.ts'/>
/// <reference path='../Models/LoudnessAccumulator.ts'/>
var GLController = (function () {
    function GLController(audioManager, videoManager, controlsProvider, shadersUrl) {
        var _this = this;
        this._meshSubject = new Rx.Subject();
        this.MeshObservable = this._meshSubject.asObservable();
        this._resolutionProvider = new ResolutionProvider();
        this._timeProvider = new TimeProvider();
        this._shadersUrl = shadersUrl;
        this._shaderLoader = new ShaderLoader(controlsProvider == null ? 'no_controls.frag' : 'controls_init.frag', 'util.frag', shadersUrl);
        var audioUniformProvider = new AudioUniformProvider(audioManager);
        var loudnessAccumulator = new LoudnessAccumulator(audioManager);
        var properties = [
            this._resolutionProvider, this._timeProvider,
            audioUniformProvider, loudnessAccumulator
        ];
        if (videoManager != null) {
            properties.push(videoManager);
        }
        if (controlsProvider != null) {
            controlsProvider.glProperties()
                .flatMap(Rx.Observable.from)
                .filter(function (uniform) { return uniform.name == "volume"; })
                .subscribe(function (volumeUniform) { return loudnessAccumulator.setVolumeUniform(volumeUniform); });
            properties.push(controlsProvider);
        }
        this._audioShaderPlane = new PropertiesShaderPlane(properties);
        this._audioShaderPlane.MeshObservable.subscribe(function (mesh) { return _this.onNewMeshes([mesh]); });
    }
    GLController.prototype.onNewResolution = function (resolution) {
        this._resolutionProvider.updateResolution(new THREE.Vector2(resolution.width, resolution.height));
    };
    GLController.prototype.onNewMeshes = function (meshes) {
        this._meshSubject.onNext(meshes);
    };
    GLController.prototype.onShaderUrl = function (url) {
        var _this = this;
        this._shaderLoader.getShaderFromServer(url)
            .subscribe(function (shader) { return _this._audioShaderPlane.onShaderText(shader); });
    };
    GLController.prototype.update = function () {
        this._timeProvider.updateTime();
    };
    return GLController;
})();
var ShadersController = (function () {
    function ShadersController(shaders) {
        this._shaders = shaders;
        this._shaderUrlSubject = new Rx.Subject();
        this.ShaderUrlObservable = this._shaderUrlSubject.asObservable();
    }
    ShadersController.prototype.shaderNames = function () {
        var shaderNames = [];
        this._shaders.forEach(function (shader) { return shaderNames.push(shader.name); });
        return shaderNames;
    };
    ShadersController.prototype.onShaderName = function (shaderName) {
        var shaderUrl;
        this._shaders.forEach(function (shader) {
            if (shader.name == shaderName) {
                shaderUrl = shader.url;
            }
        });
        if (shaderUrl != undefined) {
            this._shaderUrlSubject.onNext(shaderUrl);
        }
    };
    return ShadersController;
})();
/// <reference path='../Controllers/ShadersController'/>
var ShadersView = (function () {
    function ShadersView(shadersController) {
        this._shadersController = shadersController;
    }
    ShadersView.prototype.render = function (el) {
        var _this = this;
        var container = $("<div>", { class: "shaders" });
        var select = $("<select />");
        select.change(function (__) {
            return _this._shadersController.onShaderName(select.find('option:selected').val());
        });
        this._shadersController.shaderNames().forEach(function (shaderName) {
            return select.append("<option value=\"" + shaderName + "\">" + shaderName + "</option>");
        });
        container.append(select);
        $(el).append(container);
    };
    return ShadersView;
})();
var VideoView = (function () {
    function VideoView(videoController) {
        this._video = document.createElement("video");
        this._video.setAttribute("class", "camera");
        this._video.setAttribute("autoplay", "true");
        this._video.setAttribute("muted", "true");
        this._video.setAttribute("src", ".ignored/video.mp4");
        this._videoController = videoController;
        navigator["getUserMedia"] = navigator["getUserMedia"] ||
            navigator["webkitGetUserMedia"] ||
            navigator["mozGetUserMedia"];
        window["URL"] = window["URL"] || window["webkitURL"];
    }
    VideoView.prototype.render = function (el) {
        // var gotStream = (stream) => {
        // 	if (window["URL"])
        // 	{   this._video.src = window["URL"].createObjectURL(stream);   }
        // 	else // Opera
        // 	{   this._video.src = stream;   }
        //
        // 	this._video.onerror = function(e)
        // 	{   stream.stop();   };
        // }
        // navigator["getUserMedia"]({audio: false, video: true}, gotStream, console.log);
        $(el).append(this._video);
        this._videoController.setVideoSource(this._video);
    };
    return VideoView;
})();
var VideoManager = (function () {
    function VideoManager() {
        this._videoCanvas = document.createElement("canvas");
        this._videoCanvas.width = window.innerWidth;
        this._videoCanvas.height = window.innerHeight;
        this._videoContext = this._videoCanvas.getContext("2d");
        var texture = new THREE.Texture(this._videoCanvas);
        this._videoTexture = {
            name: "camera",
            type: "t",
            value: texture
        };
    }
    VideoManager.prototype.updateVideoElement = function (videoElement) {
        this._videoElement = videoElement;
    };
    VideoManager.prototype.glProperties = function () {
        return Rx.Observable.just([this._videoTexture]);
    };
    VideoManager.prototype.sampleVideo = function () {
        if (this._videoElement == undefined) {
            return;
        }
        this._videoContext.drawImage(this._videoElement, 0, 0, this._videoCanvas.width, this._videoCanvas.height);
        this._videoTexture.value.needsUpdate = true;
    };
    return VideoManager;
})();
/// <reference path='../Models/VideoManager.ts'/>
var VideoController = (function () {
    function VideoController(videoManger) {
        this._videoManager = videoManger;
    }
    Object.defineProperty(VideoController.prototype, "Manager", {
        get: function () {
            return this._videoManager;
        },
        enumerable: true,
        configurable: true
    });
    VideoController.prototype.setVideoSource = function (videoElement) {
        this._videoManager.updateVideoElement(videoElement);
    };
    return VideoController;
})();
var VolumeControl = (function () {
    function VolumeControl() {
        this.VolumeLevel = {
            name: "volume",
            type: "f",
            value: 1.0
        };
    }
    VolumeControl.prototype.updateVolume = function (volume) {
        this.VolumeLevel.value = volume;
    };
    return VolumeControl;
})();
var HueControl = (function () {
    function HueControl() {
        this.HueShift = {
            name: "hue",
            type: "f",
            value: 0.0
        };
    }
    HueControl.prototype.updateHueShift = function (shift) {
        this.HueShift.value = shift;
    };
    return HueControl;
})();
/// <reference path='./VolumeControl.ts'/>
/// <reference path='./HueControl.ts'/>
var ControlsProvider = (function () {
    function ControlsProvider() {
        this._volumeControl = new VolumeControl();
        this._hueControl = new HueControl();
    }
    ControlsProvider.prototype.glProperties = function () {
        return Rx.Observable.just([this._volumeControl.VolumeLevel, this._hueControl.HueShift]);
    };
    ControlsProvider.prototype.updateVolume = function (volume) {
        this._volumeControl.updateVolume(volume);
    };
    ControlsProvider.prototype.updateHueShift = function (shift) {
        this._hueControl.updateHueShift(shift);
    };
    return ControlsProvider;
})();
/// <reference path='../Models/ControlsProvider.ts'/>
var ControlsController = (function () {
    function ControlsController() {
        this.UniformsProvider = new ControlsProvider();
    }
    ControlsController.prototype.onVolumeChange = function (volume) {
        this.UniformsProvider.updateVolume(parseFloat(volume));
    };
    ControlsController.prototype.onHueShiftChange = function (shift) {
        this.UniformsProvider.updateHueShift(parseFloat(shift));
    };
    return ControlsController;
})();
var ControlsView = (function () {
    function ControlsView(controller) {
        this._controlsController = controller;
    }
    ControlsView.prototype.render = function (el) {
        var container = $("<div>", { class: "controls shader-controls" });
        this.renderVolume(container);
        this.renderHue(container);
        $(el).append(container);
    };
    ControlsView.prototype.renderVolume = function (container) {
        var _this = this;
        var volumeContainer = $("<div>");
        volumeContainer.append("Volume: ");
        var volumeSlider = $("<input>", { type: "range", min: 0, max: 2.0, step: 0.05 });
        volumeSlider.on('input', function (__) {
            _this._controlsController.onVolumeChange(volumeSlider.val());
        });
        volumeContainer.append(volumeSlider);
        container.append(volumeContainer);
    };
    ControlsView.prototype.renderHue = function (container) {
        var _this = this;
        var hueContainer = $("<div>");
        hueContainer.append("Hue: ");
        var hueSlider = $("<input>", { type: "range", min: -0.5, max: 0.5, step: 0.05 });
        hueSlider.on('input', function (__) {
            _this._controlsController.onHueShiftChange(hueSlider.val());
        });
        hueContainer.append(hueSlider);
        container.append(hueContainer);
    };
    return ControlsView;
})();
/// <reference path="./PlayerView.ts"/>
/// <reference path="./PlaylistView.ts"/>
/// <reference path="../Controllers/PlayerController.ts"/>
/// <reference path="./GLView.ts"/>
/// <reference path="../Controllers/GLController.ts"/>
/// <reference path="./ShadersView.ts"/>
/// <reference path="./VideoView.ts"/>
/// <reference path="../Controllers/VideoController.ts"/>
/// <reference path="../Controllers/ControlsController.ts"/>
/// <reference path="./ControlsView.ts"/>
/// <reference path='./IControllerView.ts' />
/// <reference path='../Models/AudioManager.ts' />
/// <reference path='../Models/Track.ts' />
/// <reference path='../Models/Shader.ts' />
var GLVis;
(function (GLVis) {
    var FileInput = (function () {
        function FileInput(tracks, shaders, shaderUrl) {
            var _this = this;
            this.content = $("<div>");
            window["AudioContext"] = window["AudioContext"] || window["webkitAudioContext"];
            this._audioManager = new AudioManager(new AudioContext());
            this._playerController = new PlayerController(tracks, this._audioManager);
            this._shadersController = new ShadersController(shaders);
            this._glController = new GLController(this._audioManager, null, null, shaderUrl);
            this._playerView = new PlayerView(this._playerController);
            this._playlistView = new PlaylistView(this._playerController);
            this._glView = new GLView(this._playerController.manager, this._glController);
            this._shadersView = new ShadersView(this._shadersController);
            this._shadersController.ShaderUrlObservable.subscribe(function (url) {
                return _this._glController.onShaderUrl(url);
            });
            this._glController.onShaderUrl(shaders[0].url);
        }
        FileInput.prototype.render = function (el) {
            var _this = this;
            this._playerView.render(this.content[0]);
            this._playlistView.render(this.content[0]);
            this._glView.render(this.content[0]);
            this._shadersView.render(this.content[0]);
            $(el).append(this.content);
            requestAnimationFrame(function () { return _this.animate(); });
        };
        FileInput.prototype.animate = function () {
            var _this = this;
            requestAnimationFrame(function () { return _this.animate(); });
            this._audioManager.sampleAudio();
            this._glView.animate();
        };
        return FileInput;
    })();
    GLVis.FileInput = FileInput;
})(GLVis || (GLVis = {}));
