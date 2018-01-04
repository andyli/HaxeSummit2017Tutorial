import kha.*;
import kha.math.FastMatrix3;
using kha.graphics2.GraphicsExtension;
import game.*;
using Lambda;

#if MULTIPLAYER
import haxe.Serializer;
import haxe.Unserializer;
import mp.Command;
import mp.Message;
#end

class Main {

	var world:World;
	var state:GameState;
	var connected = false;
	var id:Null<Int> = null;
	var cameraScale = 1.0;
	#if MULTIPLAYER
	var ws:haxe.net.WebSocket;
	#end
	
	public function new() {
		trace("built at " + BuildInfo.getBuildDate());

		#if MULTIPLAYER
			ws = haxe.net.WebSocket.create("ws://127.0.0.1:8888");
			ws.onopen = function() ws.sendString(Serializer.run(Join));
			ws.onmessageString = function(msg) {
				var msg:Message = Unserializer.run(msg);
				switch msg {
					case Joined(id): this.id = id;
					case State(state): this.state = state;
				}
			}
		#else
			world = new World();
			id = world.createPlayer().id;
		#end
		
		System.notifyOnRender(render);
		Scheduler.addTimeTask(update, 0, 1 / 60);

		kha.input.Mouse.get().notify(onmousedown, onmouseup, onmousemove, null, null);
	}

	function update() {
		#if MULTIPLAYER
			ws.process();
			if(state == null) return; // not ready
		#else
			state = world.update();
		#end

		// handle move
		var player = state.objects.find(function(o) return o.id == id);
		if(player != null) {
			// move player
			if(touched) {
				var dir = Math.atan2(cursor.y - System.windowHeight() / 2, cursor.x - System.windowWidth() / 2);
				#if MULTIPLAYER
					if(player.speed == 0) ws.sendString(Serializer.run(StartMove));
					ws.sendString(Serializer.run(SetDirection(dir)));
				#else
					player.speed = 3;
					player.dir = dir;
				#end
			} else {
				#if MULTIPLAYER
					if(player.speed != 0) ws.sendString(Serializer.run(StopMove));
				#else
					player.speed = 0;
				#end
			}

			// update camera
			var scale = 40 / player.size;
			cameraScale = cameraScale + (scale - cameraScale) * 0.25;
		}
	} //update

	function render(fb:Framebuffer):Void {
		var g = fb.g2;
		g.begin(true);

		var player = state.objects.find(function(o) return o.id == id);
		if(player != null) {
			// update camera
			var m = FastMatrix3.identity();
			m = m.multmat(FastMatrix3.translation(
				(System.windowWidth() * 0.5 - player.x * cameraScale),
				(System.windowHeight() * 0.5 - player.y * cameraScale)
			));
			m = m.multmat(FastMatrix3.scale(cameraScale, cameraScale));
			g.pushTransformation(m);
		}

		for(object in state.objects) {
			g.color = 0xff000000 | object.color;
			g.fillCircle(object.x, object.y, object.size * 0.5);
		}
		if(player != null) {
			g.popTransformation();
		}
		g.end();
	}

	var touched:Bool = false;
	var cursor = {x:0.0, y:0.0};
	function onmousedown(button:Int, x:Int, y:Int) {
		touched = true;
		cursor.x = x;
		cursor.y = y;
	}
	
	function onmousemove(x:Int, y:Int, movementX:Int, movementY:Int) {
		cursor.x = x;
		cursor.y = y;
	}

	function onmouseup(button:Int, x:Int, y:Int) {
		touched = false;
	}

	public static function main() {
		System.init({title: "Agar Clone", width: 800, height: 600, samplesPerPixel: 4}, function() {
			new Main();
		});
	}
}
