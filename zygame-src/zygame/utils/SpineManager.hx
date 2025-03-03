package zygame.utils;

import openfl.events.Event;
import openfl.display.Stage;
import spine.base.SpineBaseDisplay;
import spine.openfl.SkeletonAnimation;

/**
 * 用于管理Spine的动画统一播放处理
 */
class SpineManager {

#if debug
	public static var pathConstraintsCount(default, null):Int;
	public static var transformConstraintsCount(default, null):Int;
	public static var slotCount(default, null):Int;
	public static var boneCount(default, null):Int;
	public static var objCount(default, null):Int;
	public static var updatedObjectsList(default, null):Array<String> = [];
#end

	private static var spineOnFrames:Array<SpineBaseDisplay> = [];

	private static var stage:Stage;

	/**
	 * 当前延迟FPS的间隔时间
	 */
	private static var _lastFpsTime:Float;

	private static var _newFpsTime:Float;

	/**
	 * 是否锁定FPS时间
	 */
	public static var isLockFrameFps:Bool = false;

	/**
	 * 初始化更新器
	 * @param stage
	 * @param isLockFrameFps 是否根据帧频率来播放动画，默认为false
	 */
	public static function init(pstage:Stage, isLockFrameFps:Bool = false):Void {
		if (stage != null)
			return;
		stage = pstage;
		_lastFpsTime = Date.now().getTime();
		stage.addEventListener(Event.ENTER_FRAME, onFrame);
	}

	public static function pause():Void {
		if (stage == null)
			return;

		stage.removeEventListener(Event.ENTER_FRAME, onFrame);
	}

	public static function resume():Void {
		if (stage == null)
			return;

		if (!isLockFrameFps) {
			_lastFpsTime = Date.now().getTime();
		}

		stage.addEventListener(Event.ENTER_FRAME, onFrame);
	}

	private static function onFrame(event:Event):Void {
		
#if debug
		boneCount = 0;
		slotCount = 0;
		transformConstraintsCount = 0;
		pathConstraintsCount = 0;
		objCount = 0;

		var objNames:Array<String> = [];
		
		for (display in spineOnFrames)
		{
			if (Std.isOfType(display, SkeletonAnimation) && display.isPlay)
			{
				objCount++;
				var assetId = cast(display, SkeletonAnimation).assetsId;
				var assetName = assetId.substr(0, assetId.length - 32);
				objNames.push(assetName);
				boneCount += cast(display, SkeletonAnimation).skeleton.bones.size;
				slotCount += cast(display, SkeletonAnimation).skeleton.slots.size;
				transformConstraintsCount += cast(display, SkeletonAnimation).skeleton.transformConstraints.size;
				pathConstraintsCount += cast(display, SkeletonAnimation).skeleton.pathConstraints.size;
			}
		}

		updatedObjectsList = objNames; 
#end 

		_newFpsTime = Date.now().getTime();
		var currentFpsTime = _newFpsTime - _lastFpsTime;
		currentFpsTime = currentFpsTime / 1000;
		_lastFpsTime = _newFpsTime;
		for (display in spineOnFrames) {
			if (display.independent)
				display.onSpineUpdate(currentFpsTime);
		}
		if (!isLockFrameFps) {
			for (display in spineOnFrames) {
				if (!display.independent)
					display.onSpineUpdate(currentFpsTime);
			}
		} else {
			for (display in spineOnFrames) {
				if (!display.independent)
					display.onSpineUpdate(1 / stage.frameRate);
			}
		}
	}

	/**
	 * 添加到更新器中
	 * @param spine
	 */
	public static function addOnFrame(s:SpineBaseDisplay):Void {
		if (spineOnFrames.indexOf(s) == -1)
			if (Std.isOfType(s, spine.openfl.SkeletonSpriteBatchs))
				spineOnFrames.push(s);
			else
				spineOnFrames.insert(0, s);
	}

	/**
	 * 从更新器中移除
	 * @param spine
	 */
	 
	public static function removeOnFrame(spine:SpineBaseDisplay):Void {
		spineOnFrames.remove(spine);
	}
}
