package com.massiveProCreation.flipbook.ui
{
	// imports
	import flash.display.Sprite;
	import flash.text.TextFieldAutoSize;
	import flash.display.BlendMode;
	
	public class Information extends Sprite
	{
		public function Information(text:String)
		{
			// here we setup the text field
			super();
			this.mouseChildren = false;
			this.mouseEnabled = false;
			title.autoSize = TextFieldAutoSize.LEFT;
			title.text = text;
			title.x = 5;
			bg.width = title.width + 10;
			
			title.blendMode = BlendMode.LAYER;
		}
	}
}