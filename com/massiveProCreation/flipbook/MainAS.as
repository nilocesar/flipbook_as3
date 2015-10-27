﻿package com.massiveProCreation.flipbook
{ 
	// IMPORTS
	
	import com.asual.swfaddress.*;
	import com.greensock.TweenMax;
	import com.greensock.easing.*;
	import com.massiveProCreation.events.*;
	import com.massiveProCreation.flipbook.sound.*;
	import com.massiveProCreation.flipbook.ui.*;
	import com.massiveProCreation.utils.loaders.XMLLoaderImproved;
	
	import fl.motion.CustomEase;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.printing.PrintJob;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	
	import org.alivepdf.layout.*;
	import org.alivepdf.pdf.PDF;
	
	public class MainAS extends Sprite
	{
		//VARIABLES
		private var _page:MovieClip;											// represents a single page
		private var _xmlLoader:XMLLoaderImproved = new XMLLoaderImproved();		// xml loader
		private var _loader:Loader = new Loader();								// loader, used to load images
		private var _zoomLoader:Loader = new Loader();
		private var _pageContainer:Sprite = new Sprite();						// pages container
		private var _covers:Array = new Array();								// covers array
		private var _xml:XML;													// xml 
		private var _mask:Sprite;												// mask
		private var _ssTimer:Timer;												// slide show timer
		// modules			
		private var _fb:FlipBook;												// flip book
		private var _addPage:AddPage;											// add page button
		private var _cb:ChooseBook;												// choose book 
		private var _tt:ToolTip;												// tool tip module
		private var _contact:Contact;											// contact form module
		private var _tell:TellAFriend;
		private var _copyright:Copyright;										// copyright footer
		private var _alert:Alert;												// alert module
		private var _cp:ControlPanel = new ControlPanel();						// control panel module, contains all the upper navigation
		private var _sp:ScrollPanel;											// scroll panel
		private var _preloader:Sprite = new PleaseWeit();						// preloader animaton
		private var _sc:SoundControl;											// sound class, load and plays the music
		// properties
		private var _book:int = -1;												// book id
		private var _ctl:int = 0;												// index
		private var _zoomed:Boolean = false;									// to easly check if page zoomed
		private var _fbVis:Boolean = false;										// to easly check if flipbook visible
		private var _fbDown:Boolean = true;										// to easly check if flipbook down
		private var _firstRun:Boolean = true;									// first run value true, other false
		private var _resizeBg:Boolean = false;
		private var _myPdf:PDF;
		private var _arrows:Boolean = true;	
		private var _whereToStart:int = 0;
		private var _open:String = "";
		private var _urlTimer:Timer;
		private var _fbLoading:Boolean = false;
		
		public function MainAS()
		{
			super();																// call constructor of super class		
			this.addEventListener(Event.ADDED_TO_STAGE, added, false, 0 , true);	// add event, added to stage

		}
		private function added(e:Event):void {
		//	MacMouseWheel.setup( stage );
			visibleFalse();																	// call visibleFalse function ,sets the visibility of objects to false
			_preloader.alpha = 0;															// set prelaoder alpha, x and y
			_preloader.x = stage.stageWidth / 2;
			_preloader.y = stage.stageHeight / 2;
			
			SWFAddress.addEventListener(SWFAddressEvent.CHANGE, onAddressChange, false, 0, true);
		
			var obj:Object = _preloader.getChildByName("tekst");							// link obj to the preloaders text, then to txt and title
			
			if(obj.getChildByName("txt") != null){
				obj = obj.getChildByName("txt");
				obj = obj.getChildByName("title");
				if(root.loaderInfo.parameters.preloaderMessage != undefined)
					obj.text = String(root.loaderInfo.parameters.preloaderMessage)
				else	
					obj.text = "LOADING XML";														// then assign to it the "LOADING XML" title
			
				addChild(_preloader);
				TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut});
			}
			
			stage.addEventListener(Event.RESIZE, onResize, false, 0, true);					// add resize event
			_xmlLoader.addEventListener(CustomEvent.XML_LOADED, xmlLoaded, false, 0, true); // add xml laod event
			if(root.loaderInfo.parameters.xmlPath != undefined)
				_xmlLoader.loadXml(String(root.loaderInfo.parameters.xmlPath));
			else	
				_xmlLoader.loadXml("setup.xml");												// load the setup.xml file
			
		}
		private function xmlLoaded(e:CustomEvent):void {
			
			_xml = new XML(_xmlLoader.getXML());											// when xml loaded, assign it to the variable
			 bg.alpha = 0;																	// set the background to 0
			var obj:Object = _preloader.getChildByName("tekst");							// set the text of the prelaoder 
			obj = obj.getChildByName("txt");
			obj = obj.getChildByName("title");
			obj.text = String(_xml.setup.preloading.background.@src);
			
			if(String(_xml.setup.background.@resize) == "true")
				_resizeBg = true;
			else
				_resizeBg = false;
					
			
			if(String(_xml.setup.pdf.setup.@type) == "A3")
				_myPdf = new PDF(Orientation.PORTRAIT, Unit.MM, Size.A3);
			else if(String(_xml.setup.pdf.setup.@type) == "A4")
				_myPdf = new PDF(Orientation.PORTRAIT, Unit.MM, Size.A4);
			else 
				_myPdf = new PDF(Orientation.PORTRAIT, Unit.MM, Size.A5);
				
			 
			 if(String(_xml.setup.background.@type) == "color"){										// setup the background, if type color then draw color rectangle
			 	bg.graphics.beginFill(uint(_xml.setup.background.@src), 1);
			 	bg.graphics.drawRect(0, 0, 1920, 1080);
			 	bg.graphics.endFill();
				TweenMax.to(bg, 1, {alpha:1, ease:Expo.easeOut });
				afterBg();
			 } else if (String(_xml.setup.background.@type) == "image"){								// if type of background image, then load image
			 	_loader.unload();
			 	_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, bgLoaded, false, 0, true);
			 	_loader.load(new URLRequest(String(_xml.setup.background.@src)));
			 } else {
				 afterBg();
			 }
		
			
		}
		private function bgLoaded(e:Event):void {
			bg.addChild(_loader.content);																// when background loaded, add it to the moveiclip and tween its alpha
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, bgLoaded);
			
			if(_resizeBg && stage){
				var ratio:Number = bg.height / bg.width;
				bg.width = stage.stageWidth;
				bg.height = bg.width * ratio;
				
				if(bg.height < stage.stageHeight){
					ratio = bg.width / bg.height;
					bg.height = stage.stageHeight;
					bg.width = bg.height * ratio;
				}
			}
			
			TweenMax.to(bg, 1, {alpha:1, ease:Expo.easeOut });
			afterBg();
		}
		
		private function afterBg():void{
			var obj:Object = _preloader.getChildByName("tekst");										// set the title of the preloader
			obj = obj.getChildByName("txt");
			obj = obj.getChildByName("title");
			loadCover();
			
			_book = 0;
			var ar:Array = SWFAddress.getPathNames();
			if(_xml != null)
				var length:uint = _xml.flipbook.length();
			var bookId:int = -1;
			
			
			for(var i:int = 0; i < length; i++){
				if(_xml.flipbook[i].@title == ar[0]){
					bookId = i;
					break;
				}
			}
			if(String(_xml.setup.start.@book) != "none" && bookId == -1){
				SWFAddress.setValue( String(_xml.flipbook[int(_xml.setup.start.@book)].@title) + "/0");
				ar = SWFAddress.getPathNames();
				
				for(i = 0; i < length; i++){
					if(_xml.flipbook[i].@title == ar[0]){
						bookId = i;
						break;
					}
				}
			}
			
			if (bookId != -1){
				if(_book != bookId && bookId > -1){
					_book = bookId;
					_whereToStart = ar[1];
					KillFb();
					
				} else if ( _book == bookId){
					_whereToStart = ar[1];
				} 
				
				addFlipBook();
				
				if(String(ar[2]) != "" && String(ar[2]) != "undefined"){		
					TweenMax.to(this, 2, {alpha:1, onComplete:switchCategory, onCompleteParams:[String(ar[2])] });
				}	
			}
		}		
		
		private function selectXML(index:int):XML {
			var tmp:XML = new XML (_xml.flipbook[index]);												// this function selects the part of xml file that is needed for flipbook to work 
			return tmp;
		}
		private function loadCover():void {
			var obj:Object = _preloader.getChildByName("tekst");										// set the title of the preloader
			obj = obj.getChildByName("txt");
			obj = obj.getChildByName("title");// else show flipbook
			obj.text = String(_xml.setup.preloading.covers.@src);
			try{
			_loader.unload();																			// load flip book covers
			} catch (e:Error){
				trace("er");
			}
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, coverLoaded, false, 0, true);
			_loader.load(new URLRequest(String(_xml.flipbook[_ctl].page[0].@src)));
		}
		private function coverLoaded(e:Event):void {
			_covers.push(_loader.content);																// when cover loaded add it to the array, if there are more covers,
			_ctl++																						// load them, else show covers
			if(_xml.flipbook.length() > _ctl){
				loadCover();
			} else {
				var ar:Array = SWFAddress.getPathNames();

				if(ar.length == 0){
					if(_xml.flipbook.length() > 1){
						showPages(_covers, "category");
					} else {
						_book = 0;			
						var obj:Object = _preloader.getChildByName("tekst");										// set the title of the preloader
						obj = obj.getChildByName("txt");
						obj = obj.getChildByName("title");// else show flipbook
						obj.text = String(_xml.setup.preloading.background.@book);
						addFlipBook();	
					}
					if(_preloader)
						TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_preloader] });
				}
			}
		}
		private function visibleFalse():void {															// set objects visiblity to false, this function is used at the begening 
			nextPage.visible = false;
			previewPage.visible = false;
			_cp.visible = false;
			bg.mouseEnabled = false;
		}
		private function addFlipBook():void {
			if(_fb != null && this.contains(_fb))														// remove old flip book
				this.removeChild(_fb);
				
			_fb = null;			
			_fb = new FlipBook();																		// crate new flip book add it to stage
			_fb.name = "flipBook";
			_fbLoading = true;
			addChild(_cp);
			addChild(_fb); 
			_fb.startPosition = _whereToStart;
			_fb.xml = selectXML(_book);																	// send the xml to the book
			_fb.title = _xml.flipbook[_book].@title;
			_fb.x = (stage.stageWidth - _fb.fbWidth) / 2;												// set the x and y values 
			_fb.y = stage.stageHeight + 100;
			_fb.addEventListener(CustomEvent.READY_TO_DISPLAY, startFlipbook, false, 0, true);			// add event to the flip book
			_fb.addEventListener(CustomEvent.PAGE_CHANGE, pageChanged, false, 0, true);
			_fb.addEventListener(CustomEvent.DISABLE_UI, disableUi, false, 0, true);
			_fb.addEventListener(CustomEvent.ENABLE_UI, enableUi, false, 0, true);

			// duble click to zoom
			
			if(String(_xml.flipbook[_book].@zoom) == "true")
				_fb.addEventListener(CustomEvent.DOUBLE_PAGE_CLICK, doubleClickZoom, false, 0, true);
			
			_cp.x = ((stage.stageWidth - _fb.fbWidth) / 2) + 5;											// setup control panel on the stage
			_cp.y = ((stage.stageHeight - _fb.fbHeight) / 2);
			_cp.alpha = 0;
			_cp.mouseChildren = true;
			if(_firstRun){
				_cp.xml = _xml;																				// send xml to the control panel
				_cp.addEventListener(CustomEvent.READY_TO_DISPLAY, setupControlPanel, false, 0, true);	
			}
		}
		private function startFlipbook(e:CustomEvent):void {
			//trace("START FLIP BOOK");
			_fb.interactive(false, 2);
			_fbLoading = false;
			if(_preloader)
				TweenMax.to(_preloader, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_preloader]});
			
			if(_cb)
				TweenMax.to(_cb, 1, {alpha:0, delay:0.75, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_cb]});

			if(_sp && this.contains(_sp))
				TweenMax.to(_sp, 1, {x:0 - _sp.width - stage.stageWidth/2, delay:0.75, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_sp]});  

			_cp.visible = true;
			_cp.alpha = 0;
			
			nextPage.visible = true;																	// set the properties of the arrow
			previewPage.alpha = 0;
			previewPage.y = (stage.stageHeight /2) - 30 ;
			nextPage.y = stage.stageHeight + 100;
			previewPage.x = _fb.x - 10;
			nextPage.x = _fb.x + _fb.fbWidth +  10;
			
			if(String(_xml.flipbook[_book].music.@autoPlay) == "true" && !_firstRun)
				_cp.getChildByName("music").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			
			TweenMax.to(nextPage, 2, {y:(stage.stageHeight /2) - 30, delay:2, ease:Expo.easeOut });
			
			
			TweenMax.to(_fb, 2, {y: ((stage.stageHeight - _fb.fbHeight) / 2) + 25, delay:2, ease:Expo.easeOut , onComplete:_fb.interactive, onCompleteParams:[true, 56]});
			_fbDown = false;
			if(_firstRun)
				_firstRun = false;
			else
				TweenMax.to(_cp, 2, {alpha:1, delay:2, ease:Expo.easeOut });
			
		}
		private function setupControlPanel(e:CustomEvent):void {
			
			/* In this function the control panel and other UI is setup, first the copyright footer is set on the stage,
			 * the feature have it's click event added (before that there is an if statment which check if the feature
			 * is enabled) At the end we add the events to the next and preview arrows if they are enbaled otherwise 
			 * the visibility of those arrows is set to false
			 */
			TweenMax.to(_cp, 2, {alpha:1, delay:2, ease:Expo.easeOut });
			
			if(String(_xml.setup.copyrights.@state) == "enabled"){
				_copyright = new Copyright(String(_xml.setup.copyrights.@src));	
				_copyright.buttonMode = true;
				if(String(_xml.setup.copyrights.@url) != "")
					_copyright.addEventListener(MouseEvent.CLICK, copyrightClick, false, 0, true);	
				_copyright.alpha = 0;
				_copyright.mouseEnabled = true;
				_copyright.mouseChildren = false;
				_copyright.x = stage.stageWidth / 2;
				_copyright.y = stage.stageHeight - 25;
				addChild(_copyright)
			}
			TweenMax.to(_copyright, 1, {alpha:1, ease:Expo.easeOut });
			
			if(_xml.flipbook.length() > 1)
				_cp.getChildByName("books").addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showPages(_covers, "category");});
			
			if(String(_xml.setup.buttons.pages.@state) == "enabled")
				_cp.getChildByName("pages").addEventListener(MouseEvent.CLICK, showPagesClick, false, 0, true);
				
			if(String(_xml.setup.buttons.zoom.@state) == "enabled")
				_cp.getChildByName("zoom").addEventListener(MouseEvent.CLICK, zoomClick, false, 0, true);
				
			if(String(_xml.setup.buttons.printer.@state) == "enabled")
				_cp.getChildByName("printer").addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showPages(_fb.pages, "printer"); });
		
			if(String(_xml.setup.buttons.pdf.@state) == "enabled")
				_cp.getChildByName("pdf").addEventListener(MouseEvent.CLICK, generatePdf, false, 0, true);
			
			if(String(_xml.setup.buttons.contact.@state) == "enabled")
				_cp.getChildByName("contact").addEventListener(MouseEvent.CLICK, contactClick, false, 0, true);
			
			if(String(_xml.setup.buttons.tellAFriend.@state) == "enabled")
				_cp.getChildByName("tell").addEventListener(MouseEvent.CLICK, tellAFriendClick, false, 0, true);
			
			if(String(_xml.setup.buttons.full.@state) == "enabled")
				_cp.getChildByName("full").addEventListener(MouseEvent.CLICK, fullClick, false, 0, true);
			
			if(String(_xml.setup.buttons.slideshow.@state) == "enabled"){
				_cp.getChildByName("slideshow").addEventListener(MouseEvent.CLICK, ssClick, false, 0, true);	
				_cp.getChildByName("ssScroll").addEventListener(CustomEvent.BUTTON_CLICK, ssScroll, false, 0, true);
			}
			
			if(String(_xml.setup.buttons.music.@state) == "enabled"){
				_cp.getChildByName("music").addEventListener(MouseEvent.CLICK, musicClick, false, 0, true);
				_cp.getChildByName("volumeScroll").addEventListener(CustomEvent.BUTTON_CLICK, volumeScroll, false, 0, true);
			}
			
			if(String(_xml.setup.slideshow.@autoPlay) == "true" && String(_xml.setup.buttons.slideshow.@state) == "enabled")
			 	_cp.getChildByName("slideshow").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			
			if(String(_xml.setup.buttons.tableOfContent.@state) == "enabled")
			 	_cp.getChildByName("toc").addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {_fb.gotoPage(int(_xml.flipbook[_book].tableOfContent.@number)-1, true);});
			
			if(String(_xml.flipbook[_book].music.@autoPlay) == "true")
			 	_cp.getChildByName("music").dispatchEvent(new MouseEvent(MouseEvent.CLICK));

			if(String(_xml.setup.other.arrows.@state) == "enabled"){
				previewPage.buttonMode = true;
				previewPage.mouseChildren = false;
				previewPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				previewPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				nextPage.buttonMode = true;
				nextPage.mouseChildren = false;
				nextPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				nextPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				nextPage.addEventListener(MouseEvent.CLICK, nextPageClick, false, 0, true);
				previewPage.addEventListener(MouseEvent.CLICK, previewPageClick, false, 0, true);
			} else {
				previewPage.alpha = nextPage.alpha = 0;
				nextPage.visible = previewPage.visible = false;
			}	
		}
		private function copyrightClick(e:MouseEvent):void {
			var tar:String;
			if(String(_xml.setup.copyrights.@target) != "")
				tar = String(_xml.setup.copyrights.@target);
			else
				tar = "_blank";
				
			navigateToURL(new URLRequest(String(_xml.setup.copyrights.@url)), tar);		
		}
		private function fullClick(e:MouseEvent):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				stage.displayState=StageDisplayState.FULL_SCREEN;
				_fb.getChildByName("goToPage").alpha = 0;
			} else {
				_fb.getChildByName("goToPage").alpha = 1;
				stage.displayState=StageDisplayState.NORMAL;
			}	
			stage.dispatchEvent(new Event(Event.RESIZE));		

		}
		private function nextPageClick(e:MouseEvent):void {
			if(!_zoomed){
				if(_fb){ 												 // when next arrow is clicked, the events are removed and the page is changed
					//trace("change page");
					if(_fb.checkLoaded(_fb.currentPage + 2)){
						_fb.interactive(false, 100);
						this.uiInteractive(false);
						_fb.gotoPage(_fb.currentPage + 2, true); 
						arrowsRemoveEvents();	
					} else {
						_fb.gotoPage(_fb.currentPage + 2, true); 
					}
				}
			} else { // if zoomed
				if(_fb){ 
					
					clearZoom();
					unloadZoomLoader();
					var newScale:Number = (stage.stageWidth * 2) / (_fb.fbWidth - (int(_xml.flipbook[_book].@boarder) * 2));
					
					if(_fb.x > -100){ // if currently zoomed left page - tween to show right page
						
						TweenMax.to(_fb, 0.5, {x:-stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale), ease:Expo.easeOut, onComplete:zoomRight });

					} else {	// if currently open right page, swap page and tween to left page
						
						_fb.gotoPage(_fb.currentPage + 2, true, true); 
						_fb.interactive(false, 100);
						
						TweenMax.to(_fb, 0.5, {x:-int(_xml.flipbook[_book].@boarder) * newScale, ease:Expo.easeOut, onComplete:zoomLeft });
					}
				}
			}			
		}

		private function previewPageClick(e:MouseEvent):void {
			if(!_zoomed){
				if(_fb) {											// when preview arrow is clicked, the events are removed and the page is changed
					_fb.gotoPage(_fb.currentPage - 2, true);
					_fb.interactive(false, 99);
					this.uiInteractive(false);
					arrowsRemoveEvents();
				}
			} else {
				if(_fb){ 
					
					clearZoom();
					unloadZoomLoader();
					var newScale:Number = (stage.stageWidth * 2) / (_fb.fbWidth - (int(_xml.flipbook[_book].@boarder) * 2));
					if(_fb.x > -100){ 
						_fb.gotoPage(_fb.currentPage - 2, true, true); 
						_fb.interactive(false, 100);
						TweenMax.to(_fb, 0.5, {x:-stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale), ease:Expo.easeOut, onComplete:zoomRight });									
					} else {	
						TweenMax.to(_fb, 0.5, {x:-int(_xml.flipbook[_book].@boarder) * newScale, ease:Expo.easeOut, onComplete:zoomLeft });
					}
				}
				
			}
				
		}
		
		private function showPreloader():void {
			_preloader.alpha = 0;															// set prelaoder alpha, x and y
			_preloader.x = stage.stageWidth / 2;
			_preloader.y = stage.stageHeight / 2;
			
			var obj:Object = _preloader.getChildByName("tekst");							// link obj to the preloaders text, then to txt and title
			
			if(obj.getChildByName("txt") != null){
				obj = obj.getChildByName("txt");
				obj = obj.getChildByName("title");
				obj.text = String(_xml.setup.preloading.photo.@src);													
				addChild(_preloader);
				TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut});
			}
		}
		private function zoomRight():void {
			if(String(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+2)].@large)!= ""){
				unloadZoomLoader();
				_zoomLoader.load(new URLRequest(String(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+2)].@large)));
				showPreloader();
			}
		}
		private function unloadZoomLoader():void {
			if(_zoomLoader){
				try{
					_zoomLoader.unload();
				} catch(e:Error){
					trace("Zoom loader unload error: " + e);
				}
			}
		}
		private function zoomLeft():void {
			if(String(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+1)].@large) != ""){
				unloadZoomLoader();
				_zoomLoader.load(new URLRequest(String(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+1)].@large)));
				showPreloader();
			}
		}
		
		private function clearZoom():void {
			if(_fb.leftPage.getChildByName("big")){
				_fb.leftPage.removeChild(_fb.leftPage.getChildByName("big"));
			}
			if(_fb.rightPage.getChildByName("big")){
				_fb.rightPage.removeChild(_fb.rightPage.getChildByName("big"));
			}
			
			unloadZoomLoader()
		}
		private function musicClick(e:MouseEvent):void {
			if(_sc != null){												// music icon click, check if music is playing then stop
				if(_sc.playing){
					_sc.stopSound();
					TweenMax.killTweensOf(Sprite(_cp.getChildByName("music")).getChildAt(0));
					TweenMax.to(Sprite(_cp.getChildByName("music")).getChildAt(0), 1, {scaleX:1, scaleY:1});
					showAlert(String(_xml.setup.music.alert.off.@src), int(_xml.setup.music.alert.@delay));
				}else{														// else play music, setup volume and animate the icon
					_sc.playSound();	
					_sc.volume = Scroll(_cp.getChildByName("volumeScroll")).value;
					scaleIconDown();
					showAlert(String(_xml.setup.music.alert.on.@src), int(_xml.setup.music.alert.@delay));
				}
			} else {														// if sound control = null then we have to create the sound control object and add it to the stage
				_sc = new SoundControl(String(_xml.flipbook[_book].music.@src), Scroll(_cp.getChildByName("volumeScroll")).value, "true", String(_xml.flipbook[_book].music.@loop));
				addChild(_sc);
				showAlert(String(_xml.setup.music.alert.on.@src), int(_xml.setup.music.alert.@delay));
				_sc.volume = Scroll(_cp.getChildByName("volumeScroll")).value;
				scaleIconDown();
			}	
		}
		private function volumeScroll(e:CustomEvent):void {
			if(_sc != null)													// change the volume when the volume scroll is moved
				_sc.volume = Scroll(_cp.getChildByName("volumeScroll")).value;
		}
		private function scaleIconUp():void {								// next two functions nimate the music icon
			TweenMax.to(Sprite(_cp.getChildByName("music")).getChildAt(0), 1, {scaleX:1, scaleY:1, onComplete:scaleIconDown });
		}
		private function scaleIconDown():void {
			TweenMax.to(Sprite(_cp.getChildByName("music")).getChildAt(0), 1, {scaleX:0.9, scaleY:0.9, onComplete:scaleIconUp });
		}
		private function arrowsAddEvents():void {							// add events to the arrows (next and preview)
			if(String(_xml.setup.other.arrows.@state) == "enabled" && !_arrows){
				previewPage.buttonMode = nextPage.buttonMode = true;
				nextPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				nextPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				nextPage.addEventListener(MouseEvent.CLICK, nextPageClick, false, 0, true);
				previewPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				previewPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				previewPage.addEventListener(MouseEvent.CLICK, previewPageClick, false, 0, true);
				_arrows = true;
			}
		}
		private function arrowsRemoveEvents():void {						// remove events to the arrows (next and preview)
			if(String(_xml.setup.other.arrows.@state) == "enabled"){
				previewPage.buttonMode = nextPage.buttonMode = false;
				nextPage.removeEventListener(MouseEvent.ROLL_OUT, bOut);
				nextPage.removeEventListener(MouseEvent.ROLL_OVER, bOver);
				nextPage.removeEventListener(MouseEvent.CLICK, nextPageClick);
				previewPage.removeEventListener(MouseEvent.ROLL_OUT, bOut);
				previewPage.removeEventListener(MouseEvent.ROLL_OVER, bOver);				
				previewPage.removeEventListener(MouseEvent.CLICK, previewPageClick);
				_arrows = false;
			}
		}
		private function ssClick(e:MouseEvent):void {
			if(_ssTimer && _ssTimer.running){					// slide show click, if slide show rurnning the stop it and add interactivity to the flipbook, at the end show alert
				_fb.interactive(true, 3);
				arrowsAddEvents();
				_ssTimer.stop();
				_ssTimer.removeEventListener(TimerEvent.TIMER, timerTick);
				_ssTimer = null;
				TweenMax.killTweensOf(Sprite(_cp.getChildByName("slideshow")).getChildAt(0));
				TweenMax.to(Sprite(_cp.getChildByName("slideshow")).getChildAt(0), 1, {scaleX:1, scaleY:1 });	
				showAlert(String(_xml.setup.slideshow.alert.off.@src), int(_xml.setup.slideshow.alert.@delay));
			} else {													// else start slide show, remove the interactivity from the book and show the alert that slide show was started
				_fb.interactive(false, 4);
				arrowsRemoveEvents();
				TweenMax.to(Sprite(_cp.getChildByName("slideshow")).getChildAt(0), Scroll(_cp.getChildByName("ssScroll")).value * 0.5, {scaleX:0.8, scaleY:0.8, onComplete:rotate});	
				_ssTimer = new Timer(Scroll(_cp.getChildByName("ssScroll")).value * 1000, 0);
				_ssTimer.addEventListener(TimerEvent.TIMER, timerTick, false, 0, true);
				_ssTimer.start();
				showAlert(String(_xml.setup.slideshow.alert.on.@src), int(_xml.setup.slideshow.alert.@delay));
			}
		}
		private function rotate():void {								// rotate the slide show icon
			if(Sprite(_cp.getChildByName("slideshow")).getChildAt(0).scaleX == 1)
				TweenMax.to(Sprite(_cp.getChildByName("slideshow")).getChildAt(0), Scroll(_cp.getChildByName("ssScroll")).value * 0.5, {scaleX:0.8, scaleY:0.8, onComplete:rotate});	
			else
				TweenMax.to(Sprite(_cp.getChildByName("slideshow")).getChildAt(0), Scroll(_cp.getChildByName("ssScroll")).value * 0.5, {scaleX:1, scaleY:1, onComplete:rotate});	
		}
		private function ssScroll(e:CustomEvent):void {					// slide show scroller function, when scroller moved change the delay in the slideshow and the animation time of the icon
			if(_ssTimer != null){
				_ssTimer.stop();
				_ssTimer.removeEventListener(TimerEvent.TIMER, timerTick);
				_ssTimer = new Timer(Scroll(_cp.getChildByName("ssScroll")).value * 1000, 0);
				TweenMax.to(Sprite(_cp.getChildByName("slideshow")).getChildAt(0), Scroll(_cp.getChildByName("ssScroll")).value * 0.5, {scaleX:0.8, scaleY:0.8, onComplete:rotate});		
				_ssTimer.addEventListener(TimerEvent.TIMER, timerTick, false, 0, true);
				_ssTimer.start();
			}		
		}
		private function timerTick(e:TimerEvent):void {				// on timer tick change the page, if there are no more pages change it to the first one
			if(_fb != null) {
				var tmp:Array = _fb.pages;
				if(_fb.reverse){
					if(-1 == _fb.currentPage)
						_fb.gotoPage(tmp.length - 1, false);
					else	
						_fb.gotoPage(_fb.currentPage - 2, false);					
				} else {
					if(tmp.length - 1 == _fb.currentPage)
						_fb.gotoPage(-1, false);
					else	
						_fb.gotoPage(_fb.currentPage + 2, false);	
				}	
			}
		}
		private function stopSS():void {							// stop slide show when any other feature clicked, remove the timer event and show alert
			if(_ssTimer != null){
				_ssTimer.stop();
				_ssTimer.removeEventListener(TimerEvent.TIMER, timerTick);
				_ssTimer = null;
				TweenMax.killTweensOf(_cp.getChildByName("slideshow"));
				showAlert(String(_xml.setup.slideshow.alert.off.@src), int(_xml.setup.slideshow.alert.@delay));
			}
		}
		
		
		private function pageChanged(e:CustomEvent):void {		// when page changed, check if the page is the first page hide left arrow, 

			arrowsAddEvents();
			_fb.interactive(true, 44);
			this.uiInteractive(true);
			
			
			if(_fb.currentPage == -1){
				if(String(_xml.setup.other.arrows.@state) == "enabled"){
					if(previewPage)
						TweenMax.to(previewPage, 0.5, {alpha:0, ease:Expo.easeOut, onComplete:setVisibleFalse, onCompleteParams:[previewPage]});
					previewPage.removeEventListener(MouseEvent.ROLL_OUT, bOut);
					previewPage.removeEventListener(MouseEvent.ROLL_OVER, bOver);
				}
			} else {
				if(_ssTimer != null && !_ssTimer.running){
					if(String(_xml.setup.other.arrows.@state) == "enabled")
						if(previewPage)
							TweenMax.to(previewPage, 1, {alpha:1, delay:1, ease:Expo.easeOut });
				} else {
					if(String(_xml.setup.other.arrows.@state) == "enabled"){
						if(previewPage)
							TweenMax.to(previewPage, 1, {alpha:1, delay:1, ease:Expo.easeOut });
						previewPage.visible = true;
						previewPage.mouseEnabled = true;
						previewPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
						previewPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
					}
				}	
			}
																// if the page is last page then hide right arrow
			var tmp:Array = _fb.pages;
			
			if(tmp.length - 1 == _fb.currentPage){
				if(String(_xml.setup.other.arrows.@state) == "enabled"){
					if(nextPage)
						TweenMax.to(nextPage, 0.5, {alpha:0, ease:Expo.easeOut, onComplete:setVisibleFalse, onCompleteParams:[nextPage]});
					nextPage.removeEventListener(MouseEvent.ROLL_OUT, bOut);
					nextPage.removeEventListener(MouseEvent.ROLL_OVER, bOver);
				}
			} else {
				if(_ssTimer != null && _ssTimer.running){
					if(String(_xml.setup.other.arrows.@state) == "enabled"){
						if(nextPage)
							TweenMax.to(nextPage, 1, {alpha:1, delay:1, ease:Expo.easeOut });
						nextPage.visible = true;
					}
				} else {
					if(String(_xml.setup.other.arrows.@state) == "enabled"){
						if(nextPage)
							TweenMax.to(nextPage, 1, {alpha:1, delay:1, ease:Expo.easeOut });
						nextPage.visible = true;
						nextPage.mouseEnabled = true;
						nextPage.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
						nextPage.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
					}
				}
			}
		}
		private function setVisibleFalse(obj:Object):void {						// this function is used to set the visibility of a specified obect to false
			if(obj != null)
				obj.visible = false;
		}
		private function showAlert(str:String, delay:int):void { 				// show alert, setup the position, tween alpha 
			_alert = new Alert(str, delay);
			_alert.alpha = 0;
			_alert.addEventListener(CustomEvent.KILL, killAlert, false, 0, true);
			this.parent.addChild(_alert);
			
			if(_alert.width > 300)
				_alert.x = (stage.stageWidth / 2) - 60;
			else
				_alert.x = (stage.stageWidth / 2) + 35 ;
				
			_alert.y = stage.stageHeight / 2;
			TweenMax.to(_alert, 1, {alpha:1, ease:Expo.easeOut });
		}
		private function startPrint(e:MouseEvent):void {	
			/* This function is fired when we want to print pages, first we remove the events from the button 
			 * the we setup print veriables then we show alert that the printing have been started. Then if checks
			 * which of the bitmaps was selected, and adds it to the print job, at the end we send pages to the printer
			 * and show flipbook. If printing canceled then we show and Alert message.
			 */					
			_cb.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			_cb.removeEventListener(MouseEvent.ROLL_OVER, bOver);
			_cb.removeEventListener(MouseEvent.ROLL_OUT, bOut);
			_cb.removeEventListener(MouseEvent.CLICK, startPrint);
			
			this.getChildByName("cbPrint").dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			this.getChildByName("cbPrint").removeEventListener(MouseEvent.ROLL_OVER, bOver);
			this.getChildByName("cbPrint").removeEventListener(MouseEvent.ROLL_OUT, bOut);
			this.getChildByName("cbPrint").removeEventListener(MouseEvent.CLICK, startPrint);
			
			
			var _pj:PrintJob = new PrintJob();
			var res:Boolean = _pj.start();
			var _prints:Array = _sp.prints;
			var sprite:Sprite = new Sprite();
			var tmp:Array = _fb.pages;
			var bitmap:Bitmap;
			var bitmapData:BitmapData;
			try{	
				if(res){
					showAlert(String(_xml.setup.printer.alert.started.@src), int(_xml.setup.printer.alert.@delay));

					for(var i:int = 0; i < _prints.length; i ++){
						if(_prints[i] != -1){
							if(tmp[_prints[i]] is Bitmap){
									bitmap = new Bitmap(tmp[_prints[i]].bitmapData);
							} else {
									var area:Rectangle = new Rectangle(0, 0, tmp[_prints[i]].width, tmp[_prints[i]].height);
									bitmapData = new BitmapData(area.right, area.bottom);
									bitmapData.draw(tmp[_prints[i]]);
									bitmap = new Bitmap(bitmapData);
							}
							sprite = new Sprite();
							sprite.addChild(bitmap);
							sprite.width = _pj.pageWidth;
							sprite.height = _pj.pageHeight;
							_pj.addPage(sprite);
						} else {
							trace("page deleted");
						}
							
						} 
					
					_pj.send();
					showFb("printer");
				} else {
					showAlert(String(_xml.setup.printer.alert.canceled.@src), int(_xml.setup.printer.alert.@delay));
				}	
			} catch (e:Error){
				trace("error = " + e);
			}
			
		}
		private function zoomClick(e:MouseEvent):void {
			if(String(_xml.flipbook[_book].@zoom) == "true"){
				doubleClickZoom(null);
			} else {
				showAlert(String(_xml.setup.zoom.alert.zoomDisabled.@src), int(_xml.setup.zoom.alert.@delay));
			}
			
			
		}
		private function searchForNode(page:int):int {
			var tmpPage:int = 0;
			var desiredPage:int = page;
			
			for(var i:int = 0; i < _xml.flipbook[_book].page.length(); i++){
				
				if(String(_xml.flipbook[_book].page[i].@type) == "double"){
					tmpPage++;	
				}
				tmpPage++;
				
				
				if(tmpPage >= desiredPage){
					return i;
				}
			}
			
			return -1;
			
		}
		private function bigImageLoaded(e:Event):void {
			var spr:Sprite = new Sprite();
			spr.addChild(_zoomLoader.content);
			spr.name = "big";
			spr.mouseEnabled = false;
			spr.alpha = 0;
			Bitmap(spr.getChildAt(0)).smoothing = true;
			
			TweenMax.to(_preloader, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_preloader]});
			
			if(_fb.x > -50){
				spr.height = _fb.leftPage.getChildAt(0).height;
				if(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+1)].@type == "double")
					spr.width = _fb.leftPage.getChildAt(0).width * 2;
				else
					spr.width = _fb.leftPage.getChildAt(0).width;
				
				_fb.leftPage.addChild(spr);
			} else {
				if(_xml.flipbook[_book].page[searchForNode(_fb.currentPage+2)].@type == "double"){
					spr.width = _fb.rightPage.getChildAt(0).width * 2;
					spr.x = - _fb.rightPage.getChildAt(0).width;
				}else{
					spr.width = _fb.rightPage.getChildAt(0).width;
				}
				
				spr.height = _fb.rightPage.getChildAt(0).height;
				_fb.rightPage.addChild(spr);
			}	
			TweenMax.to(spr, 0.5, {alpha:1, ease:Expo.easeOut });
		}
		private function doubleClickZoom(e:CustomEvent):void {
		
			if(!_zoomed){
				/* ZOOM */
				unloadZoomLoader();
				if(_copyright){
					_copyright.mouseEnabled = false;
					_copyright.mouseChildren = false;
				}
				showAlert(String(_xml.setup.zoom.alert.zoomIn.@src), int(_xml.setup.zoom.alert.@delay));
				_zoomLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, bigImageLoaded, false, 0, true);
				_fb.interactive(false, 77);
				TweenMax.to(_cp, 1, {alpha:0, ease:Expo.easeOut });
				TweenMax.to(_copyright, 1, {alpha:0, ease:Expo.easeOut });
				
				var newScale:Number = (stage.stageWidth * 2) / (_fb.fbWidth - (int(_xml.flipbook[_book].@boarder) * 2));
				
				if(mouseX < stage.stageWidth * 0.5){
					zoomLeft();

					
					trace("kill");
					TweenMax.killTweensOf(_fb);
					if(_fb.currentPage != -1){
						TweenMax.to(_fb, 0.5, {x:-int(_xml.flipbook[_book].@boarder) * newScale, y:(stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5, 
										 	 scaleX:newScale , scaleY:newScale,
										  ease:Expo.easeOut, onComplete:addMouseMove});
					} else {
						TweenMax.to(_fb, 0.5, {x:-stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale) , y:(stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5, 
							scaleX:newScale , scaleY:newScale,
							ease:Expo.easeOut, onComplete:addMouseMove});
					}
				} else {
					zoomRight();
					trace("kill");
					TweenMax.killTweensOf(_fb);
					TweenMax.to(_fb, 0.5, {x:-stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale) , y:(stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5, 
						scaleX:newScale , scaleY:newScale,
						ease:Expo.easeOut, onComplete:addMouseMove});
				}
				
				_zoomed = true;
				
				this.setChildIndex(nextPage, this.numChildren - 1);
				this.setChildIndex(previewPage, this.numChildren - 1);
				nextPage.y = (stage.stageHeight - nextPage.height) * 0.5;
				nextPage.x = (stage.stageWidth - nextPage.width);
				previewPage.y = (stage.stageHeight - previewPage.height) * 0.5;
				previewPage.x = nextPage.width;
			} else if (_zoomed){
				/* UNZOOM */
				if(_copyright){
					_copyright.mouseEnabled = true;
					_copyright.mouseChildren = true;
				}
				_zoomLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, bigImageLoaded);
				TweenMax.to(_cp, 1, {alpha:1, ease:Expo.easeOut });
				TweenMax.to(_copyright, 1, {alpha:1, ease:Expo.easeOut });
				TweenMax.to(previewPage, 0.5, {x:((stage.stageWidth - _fb.fbWidth) / 2) - 10, y:(stage.stageHeight /2) - 30, ease:Expo.easeOut });
				TweenMax.to(nextPage, 0.5, {x:((stage.stageWidth - _fb.fbWidth) / 2) + _fb.fbWidth +  10, y:(stage.stageHeight /2) - 30, ease:Expo.easeOut });

				this.removeEventListener(MouseEvent.MOUSE_MOVE, moveFb);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, escPress);
				TweenMax.to(_fb, 0.5, {x:(stage.stageWidth - _fb.fbWidth) / 2, y:((stage.stageHeight - _fb.fbHeight) / 2)+25, 
									  scaleX:1, scaleY:1, ease:Expo.easeOut, onComplete:zoomed});
				
				if(_fb.leftPage.getChildByName("big")){
					_fb.leftPage.removeChild(_fb.leftPage.getChildByName("big"));
				}
				if(_fb.rightPage.getChildByName("big")){
					_fb.rightPage.removeChild(_fb.rightPage.getChildByName("big"));
				}
				
				if(_preloader)
					TweenMax.to(_preloader, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_preloader]});
				
				if(_zoomLoader){
					trace("remove loader");
					try{
						_zoomLoader.close();
						unloadZoomLoader();
					} catch(e:Error){
						trace("error on unzoom - loader: " + e);
					}
					
				}
			}
		}
		private function zoomed():void {
			
			_zoomed = false;
			_fb.interactive(true, 47);
		}
		private function addMouseMove():void {
			this.addEventListener(MouseEvent.MOUSE_MOVE, moveFb, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, escPress, false, 0, true);
		}
		private function escPress(e:KeyboardEvent):void {
			trace("KEYBOARD CLICK");
			if(e.keyCode == Keyboard.ESCAPE){
				doubleClickZoom(null);
			}
		}
		private function moveFb(e:MouseEvent):void {			// this functions tweens the flipbook to the secific position when it's zoomed and user moves the mouse
			
			if(!_fb)
				return;
			
			TweenMax.to(_fb, 1, {y:(stage.stageHeight/_fb.scaleY) -((mouseY - (stage.stageHeight/_fb.scaleY)) * 
								   ((((_fb.fbHeight * _fb.scaleY) - stage.stageHeight)/_fb.scaleY) / (stage.stageHeight/_fb.scaleY))) - (_fb.fbHeight),
								 ease:Expo.easeOut });			
				e.updateAfterEvent();
		}
		
		
		private function showPages(tmp:Array, type:String):void {
			/* This function shows the panel whit scroll pages, where you can view all the pages, there are 3 types of this panel
			 * for the book categories, printer and to see all pages. At the begening slideshow and contact is turned off, then 
			 * the flip book is hidden and the mask is drawn. Then the scroll panel is added for each type of we add the diferent 
			 * events and diferent ChooseBook modules. At the end we show the full scroll panel modul using tweener.
			 */
			
			/* Protection, the same director wont be open twice*/
			trace("show pages");
			
			if(type == _open)
				return;
			
			if(_sp){
				this.removeChild(_sp);
				_sp = null;
			}
			
			stopSS(); 
			closeContact();
			closeTellAFriend();
			
			if(type != "category")
				hideFb();
			else
				KillFb();
				
			drawMask();
			
			if(_fb != null && type != "category"){
				_sp = new ScrollPanel(tmp, type, _xml, true, _book, _fb.currentPage);
			} else {
				_sp = new ScrollPanel(tmp, type, _xml, false, _book);
			}
			
			_sp.alpha = 0;
			addChild(_sp);
			_sp.x = stage.stageWidth + 100;
			_sp.y = 200;
						
			if(type == "category")
				_sp.addEventListener(CustomEvent.PAGE_CLICK, categoryClick, false, 0, true);
			else if (type == "pages")	
				_sp.addEventListener(CustomEvent.PAGE_CLICK, pageClick, false, 0, true);

			TweenMax.to(_sp, 2, {alpha:1, x:50, delay:1, ease:Expo.easeOut });
			
			if(type == "category"){
				_open = "category";
				var ar:Array = SWFAddress.getPathNames();

				if(checkUrl("category") && ar.length > 0)
					SWFAddress.setValue("/category");
				trace("set value");
				_cb = new ChooseBook(String(_xml.setup.buttons.books.@description), type, uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
			}else if(type == "pages"){
				_open = "pages";
				if(checkUrl("pages"))
					SWFAddress.setValue(SWFAddress.getPath() + "/pages");

				_cb = new ChooseBook(String(_xml.setup.buttons.pages.@description), type, uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.name = "cbPages";
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = ((stage.stageWidth - _cb.width) / 2) - 75 ;
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
				
				_cb = new ChooseBook(String(_xml.setup.buttons.pages.@cancelText), "back", uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showFb("pages"); });
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = ((stage.stageWidth - _cb.width) / 2) + 150;
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });

				
			}else if(type == "printer"){
				_open = "printer";
				if(checkUrl("printer"))
					SWFAddress.setValue(SWFAddress.getPath() + "/printer");

				_cb = new ChooseBook(String( _xml.setup.buttons.printer.@description), type, uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, startPrint, false, 0, true);
				_cb.name = "cbPrint";
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = ((stage.stageWidth - _cb.width) / 2) - 175;
				_cb.alpha = 0;
				
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
				
				_cb = new ChooseBook(String( _xml.setup.buttons.printer.@selectAll), "selectAll", uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, selectAll, false, 0, true);
				_cb.name = "cbSelectAll";
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = this.getChildByName("cbPrint").x + this.getChildByName("cbPrint").width + 25;
				_cb.alpha = 0;
				
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
				
				_cb = new ChooseBook(String(_xml.setup.buttons.printer.@cancelText), "back", uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showFb("printer"); });
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = this.getChildByName("cbSelectAll").x + this.getChildByName("cbSelectAll").width + 25
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
			} else if (type == "pdf"){
				_open = "pdf";
				if(checkUrl("pdf"))
					SWFAddress.setValue(SWFAddress.getPath() + "/pdf");

				_cb = new ChooseBook(String(_xml.setup.buttons.pdf.@description), type, uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, pageToPdf, false, 0, true);
				_cb.name = "cbPdf";
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = ((stage.stageWidth - _cb.width) / 2) - 175;
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
				
				_cb = new ChooseBook(String( _xml.setup.buttons.pdf.@selectAll), "selectAll", uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, selectAll, false, 0, true);
				_cb.name = "cbSelectAll";
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = this.getChildByName("cbPdf").x + this.getChildByName("cbPdf").width + 25;
				_cb.alpha = 0;
				
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
				
				_cb = new ChooseBook(String(_xml.setup.buttons.printer.@cancelText), "back", uint(_xml.setup.buttons.other.@bgColor), Number(_xml.setup.buttons.other.@bgAlpha));
				_cb.buttonMode = true;	
				_cb.mouseChildren = false;
				_cb.addEventListener(MouseEvent.ROLL_OVER, bOver, false, 0, true);
				_cb.addEventListener(MouseEvent.ROLL_OUT, bOut, false, 0, true);
				_cb.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void { showFb("pdf"); });
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = this.getChildByName("cbSelectAll").x + this.getChildByName("cbSelectAll").width + 25;
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
			}	
			if( type != "printer" && type != "pdf" && type != "pages"){
				addChild(_cb);
				_cb.y = _sp.y - 100;
				_cb.x = (stage.stageWidth - _cb.width) / 2;
				_cb.alpha = 0;
				TweenMax.to(_cb, 2, {alpha:1, delay:1, ease:Expo.easeOut });
			}
		
		}
		private function selectAll(e:MouseEvent):void {
			var obj:Object = _sp.scrollContent.content;
			
			for(var i:int = 0; i < _fb.pages.length; i++){
				if(obj.getChildByName("addPage"+ i)){
					if(!obj.getChildByName("addPage"+ i).add){
						obj.getChildByName("addPage"+ i).dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
						obj.getChildByName("addPage"+ i).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					} else {
						obj.getChildByName("addPage"+ i).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
						obj.getChildByName("addPage"+ i).dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));	
					}
				}
			}
		}
		private function pageToPdf(e:MouseEvent):void {

			_cb.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			_cb.removeEventListener(MouseEvent.ROLL_OVER, bOver);
			_cb.removeEventListener(MouseEvent.ROLL_OUT, bOut);
			_cb.removeEventListener(MouseEvent.CLICK, startPrint);
			
			this.getChildByName("cbPdf").dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			this.getChildByName("cbPdf").removeEventListener(MouseEvent.ROLL_OVER, bOver);
			this.getChildByName("cbPdf").removeEventListener(MouseEvent.ROLL_OUT, bOut);
			this.getChildByName("cbPdf").removeEventListener(MouseEvent.CLICK, startPrint);
			
			var _prints:Array = _sp.prints;
			var sprite:Sprite = new Sprite();
			var tmp:Array = _fb.pages;
			var bitmap:Bitmap;
			var bitmapData:BitmapData;

			for(var i:int = 0; i < _prints.length; i ++){
				if(_prints[i] != -1){
					if(tmp[_prints[i]] is Bitmap){
						bitmap = new Bitmap(tmp[_prints[i]].bitmapData);
					} else {
						var area:Rectangle = Object(tmp[_prints[i]]).getRect(tmp[_prints[i]]);
						bitmapData = new BitmapData(area.right, area.bottom);
						bitmapData.draw(tmp[_prints[i]]);
						bitmap = new Bitmap(bitmapData);
						}
					sprite.addChild(bitmap);
					
					_myPdf.addPage();
					if(String(_xml.setup.pdf.setup.@type) == "A3"){
						_myPdf.addImage(sprite, 0, 0, 297, 420); 
					} else if(String(_xml.setup.pdf.setup.@type) == "A4"){
						_myPdf.addImage(sprite, 0, 0, 210, 297); 
					} else {
						_myPdf.addImage(sprite, 0, 0, 148, 210); 
					}
					
					} else {
						trace("page deleted");
					}
							
					} 
					_myPdf.save("remote","create.php","attachment","flipbook.pdf");
					showFb("pdf");
					_alert = new Alert(String(_xml.setup.pdf.alert.generate.@src), int(_xml.setup.pdf.alert.@delay));
					_alert.alpha = 0;
					_alert.addEventListener(CustomEvent.KILL, killAlert, false, 0, true);
					this.parent.addChild(_alert);
					_alert.x = stage.stageWidth / 2 ;
					_alert.y = stage.stageHeight / 2;
					TweenMax.to(_alert, 1, {alpha:1, ease:Expo.easeOut });
		}
		private function categoryClick(e:CustomEvent):void {
			/* When category clicked, book need to be loaded, first the preloader is setup then it's tweened. 
			 *  Then index of the book is assigned and addFlipBook function called
			 */
			_preloader.alpha = 0;
			var obj:Object = _preloader.getChildByName("tekst");
			obj = obj.getChildByName("txt");
			obj = obj.getChildByName("title");
			obj.text = String(_xml.setup.preloading.book.@src);

			obj = _sp.scrollContent.content;
			_preloader.x = _sp.x + obj.x + _sp.scrollContent.x + (obj.getChildByName("page"+_sp.pageIndex).width * 0.5) + obj.getChildByName("page"+_sp.pageIndex).x;
			_preloader.y = _sp.y + obj.y + (obj.getChildByName("page"+_sp.pageIndex).height * 0.4) + obj.getChildByName("page"+_sp.pageIndex).y;
			
			addChild(_preloader);
			_sp.removeEventListener(CustomEvent.PAGE_CLICK, categoryClick);
			_sp.removed();
			TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut });
		
			_book = _sp.pageIndex;
			SWFAddress.setValue(String(_xml.flipbook[_book].@title)+"/0");
			
			addFlipBook();		
		}
		private function showPagesClick(e:MouseEvent = null):void {
			showPages(_fb.pages, "pages");								// when show pages clicked call the show pages function
		}
		private function generatePdf(e:MouseEvent):void {
			if(String(_xml.setup.pdf.setup.@method) == "generate")
				showPages(_fb.pages, "pdf");
			else 
				navigateToURL(new URLRequest(String(_xml.flipbook[_book].@pdf)), "_blank");	
		}
		private function hideFb ():void {
			_fbDown = true;												// this funciton hides the flipbook 
			
			TweenMax.to(_fb, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut });
			TweenMax.to(nextPage, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut });
			TweenMax.to(previewPage, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut });
						
			_cp.mouseChildren = false;
			TweenMax.killTweensOf(_cp);
			TweenMax.to(_cp, 2, {alpha:0, ease:Expo.easeOut });
		}
		private function KillFb ():void {
			var obj:Object = _fb;										// this function hides the flip book and then removes it from the memory
	
			_fbDown = true;
			
			if(obj)
				TweenMax.to(_fb, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[obj]});
			TweenMax.to(nextPage, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut });
			TweenMax.to(previewPage, 2, {y: stage.stageHeight + 100, ease:Expo.easeOut });
			
			_cp.mouseChildren = false;			
			TweenMax.killTweensOf(_cp);
			TweenMax.to(_cp, 2, {alpha:0, ease:Expo.easeOut });
			if(_sc){
				_sc.stopSound();
				_sc = null;
			}
		}

		private function killAlert(e:CustomEvent):void {
			try{														// this function removes the alert from stage
				if(_alert != null && this.parent.contains(_alert)) 
					this.parent.removeChild(_alert);
			} catch (e:Error){
				trace("Moj error = " + e);
			}		
		}
		private function showFb(type = "other"):void { // in this function the flipbook is tweeed back to its original position, basicly this function shows the flipbook after it's hidden
			closeContact();
			closeTellAFriend();
			if(_sp)
				TweenMax.to(_sp, 1, {alpha:0, ease:Expo.easeOut });

			_fbDown = false;
			_cp.mouseChildren = true;
			if(_fb){
				_fb.interactive(false);
				_fb.x = (stage.stageWidth - _fb.fbWidth) / 2; 
				_cp.x = ((stage.stageWidth - _fb.fbWidth) / 2) + 5;
			
				previewPage.x = _fb.x - 10;
				nextPage.x = _fb.x + _fb.fbWidth +  10;
			}
			if (this.getChildByName("cbPrint") && this.contains(getChildByName("cbPrint"))) {
				this.getChildByName("cbPrint").removeEventListener(MouseEvent.ROLL_OVER, bOver);
				this.getChildByName("cbPrint").removeEventListener(MouseEvent.ROLL_OUT, bOut);
				TweenMax.killTweensOf(this.getChildByName("cbPrint"));
				TweenMax.to(this.getChildByName("cbPrint"), 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[this.getChildByName("cbPrint")]});
			} else if (this.getChildByName("cbPdf") && this.contains(getChildByName("cbPdf"))) {
				this.getChildByName("cbPdf").removeEventListener(MouseEvent.ROLL_OVER, bOver);
				this.getChildByName("cbPdf").removeEventListener(MouseEvent.ROLL_OUT, bOut);
				TweenMax.killTweensOf(this.getChildByName("cbPdf"));
				TweenMax.to(this.getChildByName("cbPdf"), 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[this.getChildByName("cbPdf")]});
			} else if (this.getChildByName("cbPages") && this.contains(getChildByName("cbPages"))) {
				this.getChildByName("cbPages").removeEventListener(MouseEvent.ROLL_OVER, bOver);
				this.getChildByName("cbPages").removeEventListener(MouseEvent.ROLL_OUT, bOut);
				TweenMax.killTweensOf(this.getChildByName("cbPages"));
				TweenMax.to(this.getChildByName("cbPages"), 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[this.getChildByName("cbPages")]});
			}
			
			if (this.getChildByName("cbSelectAll") && this.contains(getChildByName("cbSelectAll"))){
				this.getChildByName("cbSelectAll").removeEventListener(MouseEvent.ROLL_OVER, bOver);
				this.getChildByName("cbSelectAll").removeEventListener(MouseEvent.ROLL_OUT, bOut);
				TweenMax.killTweensOf(this.getChildByName("cbSelectAll"));
				TweenMax.to(this.getChildByName("cbSelectAll"), 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[this.getChildByName("cbSelectAll")]});
			}
			
			
			if(_cb){
				_cb.removeEventListener(MouseEvent.ROLL_OVER, bOver);
				_cb.removeEventListener(MouseEvent.ROLL_OUT, bOut);
			}
			if(_cb)
				TweenMax.to(_cb, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_cb]});
			
			if(_sp)
				TweenMax.to(_sp, 1, {x:0 - _sp.width - 200, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_sp]}); 
				
			TweenMax.to(_cp, 2, {alpha:1, delay:2, ease:Expo.easeOut});
			
			if(_fb != null){				
				TweenMax.to(_fb, 2, {y: ((stage.stageHeight - _fb.fbHeight) / 2) + 25, ease:Expo.easeOut, onComplete:_fb.interactive, onCompleteParams:[true, 19]});
				TweenMax.to(nextPage, 2, {y:(stage.stageHeight / 2) - 30, ease:Expo.easeOut });
				TweenMax.to(previewPage, 2, {y:(stage.stageHeight / 2) - 30, ease:Expo.easeOut });
			}
			if(type == "printer" || type == "pdf" || type == "pages"){
				_open="";
				var ar:Array = SWFAddress.getPathNames();
				if(ar.length > 2)
					SWFAddress.setValue("/"+ar[0]+"/"+ar[1]);
			}
		}
		private function drawMask():void {
			_mask = new Sprite();				// this funciton draws a mask
			_mask.graphics.beginFill(0xFF0000, 1);
			_mask.graphics.drawRect(0, 0, stage.stageWidth - 100, stage.stageHeight);
			_mask.graphics.endFill();
		}

		private function removeObject(obj:Sprite):void { // this function removes objects from the stage to free up the memory
			if(obj && this.contains(obj)){
				if(obj is ScrollPanel){
					_sp.removeEventListener(CustomEvent.PAGE_CLICK, categoryClick);
					_sp.removeEventListener(CustomEvent.PAGE_CLICK, pageClick);
					this.removeChild(obj);
					_sp = null;
					obj = null;
				} else if (obj is FlipBook){
					_fb.removeEventListener(CustomEvent.READY_TO_DISPLAY, startFlipbook);
					_fb.removeEventListener(CustomEvent.PAGE_CHANGE, pageChanged);
					this.removeChild(_fb);
					_fb = null;
					obj = null;
					
				} else {
					this.removeChild(obj);
					obj = null;
				}
			}	
		}
		private function pageClick(e:CustomEvent):void {	// when page clicked change it 
			_fb.interactive(false, -100);
			_fb.gotoPage(_sp.pageIndex, true, true);
			this.showFb("pages");
		}
		private function tellAFriendClick(e:MouseEvent):void {	// when tell a friend icon click, costruct tell a friend and add it to the stage.
			if(_tell && this.contains(_tell)){
				trace("already displayed");
			} else {
				stopSS();
				if(_fb)	
					_fb.interactive(false); 
				
				_open = "tell_a_friend";
				if(checkUrl("tell_a_friend"))
					SWFAddress.setValue(SWFAddress.getPath() + "/tell_a_friend");
				
				_tell = new TellAFriend();
				_tell.name = "tell";
				_tell.mouseChildren = true;
				_tell.xml = new XML(_xml.setup);
				_tell.x = stage.stageWidth / 2 + 20;
				_tell.y = (stage.stageHeight - _tell.height) / 2 ;
				_tell.alpha = 0;
				TweenMax.to(_tell, 1, {alpha:1, ease:Expo.easeOut });
				_tell.addEventListener(CustomEvent.BUTTON_CLICK, closeTellAFriend, false, 0, true);
				addChild(_tell);
			}
		}
		private function contactClick(e:MouseEvent):void {	// when contact icon click, costruct contact and add it to the stage.
			if(_contact && this.contains(_contact)){
				trace("already displayed");
			} else {
				stopSS();
				if(_fb)	
					_fb.interactive(false, 7); 
				
				_open = "contact";
				if(checkUrl("contact"))
					SWFAddress.setValue(SWFAddress.getPath() + "/contact");

				_contact = new Contact();
				_contact.name = "contact";
				_contact.mouseChildren = true;
				_contact.xml = new XML(_xml.setup);
				_contact.x = stage.stageWidth / 2 + 20;
				_contact.y = (stage.stageHeight - _contact.height) / 2 ;
				_contact.alpha = 0;
				TweenMax.to(_contact, 1, {alpha:1, ease:Expo.easeOut });
				_contact.addEventListener(CustomEvent.BUTTON_CLICK, closeContact, false, 0, true);
				addChild(_contact);
			}
		}
		private function closeTellAFriend(e:CustomEvent = null):void { // when contact closed, hide it and the remove
			_open="";
			
			if(_tell && this.contains(_tell)){
				var ar:Array = SWFAddress.getPathNames();
				_fb.interactive(true, 8);
				if(ar.length > 2)
					SWFAddress.setValue("/"+ar[0]+"/"+ar[1]);
				
				_tell.mouseChildren = false; 
				if(_tell)
					TweenMax.to(_tell, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_tell]});
			}
		}
		private function closeContact(e:CustomEvent = null):void { // when contact closed, hide it and the remove
			_open="";
			
			if(_contact && this.contains(_contact)){
				var ar:Array = SWFAddress.getPathNames();
				_fb.interactive(true, 8);
				if(ar.length > 2)
					SWFAddress.setValue("/"+ar[0]+"/"+ar[1]);

				_contact.mouseChildren = false; 
				if(_contact)
					TweenMax.to(_contact, 1, {alpha:0, ease:Expo.easeOut, onComplete:removeObject, onCompleteParams:[_contact]});
			}
		}
		private function bOut(e:MouseEvent):void { // roll out animation
			TweenMax.to(e.target, 1, {alpha:1, ease:Expo.easeOut});
		}
		private function bOver(e:MouseEvent):void {	// roll over animation
			TweenMax.to(e.target, 1, {alpha:0.8, ease:Expo.easeOut});
		}
		private function changeBook():void {
			_book = 0;		
			_whereToStart = 8;			
			addFlipBook();
		}
		private function onAddressChange(e:SWFAddressEvent):void {
			
			if(_urlTimer != null){
				_urlTimer.stop();
				_urlTimer.removeEventListener(TimerEvent.TIMER, updateOnURLChange);
				_urlTimer = null;
			}
			
 			_urlTimer = new Timer(500, 1);
			_urlTimer.addEventListener(TimerEvent.TIMER, updateOnURLChange, false, 0, true);
			_urlTimer.start();
			
			if(e != null && e.value != "/")
				SWFAddress.setTitle(String(root.loaderInfo.parameters.title) + " - " +  e.value.substring(1));
			else
				SWFAddress.setTitle(String(root.loaderInfo.parameters.title));			

			if(_fb && this.parent.getChildByName("videoPopUp")){
				this.parent.getChildByName("videoPopUp").dispatchEvent(new CustomEvent(CustomEvent.VIDEO_CLICK));
				this.parent.getChildByName("cover").alpha = 0;
			}

		}		
		
		private function updateOnURLChange(e:TimerEvent):void {
			// we recive the names of directories from the url path
			var ar:Array = SWFAddress.getPathNames();
			var tmpBook:int = _book;
			var changeBook:Boolean = false;
			
			if(_xml != null)
				var length:uint = _xml.flipbook.length();
			
			var bookId:int = -1;
			// we check the id of the book that is specified in the url
			for(var i:int = 0; i < length; i++){
				if(_xml.flipbook[i].@title == ar[0]){
					bookId = i;
					break;
				}
			}
			if(ar[1] != 0 && ar[1] % 2 != 0){
				ar[1]++;
			}

			if(String(ar[2]) == "category"){
				
				_book = -1;
				KillFb();
				ar[1] = 0;
				showPages(_covers, "category");  
				return;
			}
			//trace(SWFAddress.getPath());
			if(_book != bookId && bookId != -1){
				
				changeBook = true;
				
				_book = bookId;
				
				_whereToStart = ar[1];
				
				KillFb();
				
				_preloader.alpha = 0;
				var obj:Object = _preloader.getChildByName("tekst");
				obj = obj.getChildByName("txt");
				obj = obj.getChildByName("title");
				obj.text = String(_xml.setup.preloading.book.@src);
				
				_preloader.x = stage.stageWidth * 0.5;
				_preloader.y = stage.stageHeight * 0.5;
				addChild(_preloader);
				
				TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut, onComplete:addFlipBook});
				
			
			} else if ( _book == bookId && _fb != null && _fb.currentPage != (ar[1] - 1) && ar.length < 3){
				if(_fb.gtp != ar[1])
					_fb.gotoPage(ar[1], true);	
				if(_zoomed)
					doubleClickZoom(null);
				
			} else if (bookId == -1 && length > 1 && _xml.flipbook.length() == _covers.length && _xml.flipbook.length() > 1){
				ar[1] = 0;
				if(_open != "category")
					showPages(_covers, "category");  
			}
		
			/* Sub directories deeplinking*/
			if(_open != String(ar[2]) && String(ar[2]) != "undefined"){
				if(tmpBook != bookId){
					TweenMax.to(this, 2, {alpha:1, ease:Expo.easeOut,  onComplete:switchCategory, onCompleteParams:[String(ar[2])] });
				} else {
					switchCategory(String(ar[2]));
				}
			}
			
			if(ar.length < 3 && !changeBook && bookId != -1 && !_zoomed && _fb && !_fbLoading){
					//trace("showFB - called from DL");
					showFb();
			} else if (ar.length < 3 && !changeBook && bookId != -1 && !_zoomed && !_fb) {
				_book = bookId;
				_whereToStart = ar[1];
				
				KillFb();
				
				_preloader.alpha = 0;
				obj = _preloader.getChildByName("tekst");
				obj = obj.getChildByName("txt");
				obj = obj.getChildByName("title");
				obj.text = String(_xml.setup.preloading.book.@src);
				
				_preloader.x = stage.stageWidth * 0.5;
				_preloader.y = stage.stageHeight * 0.5;
				addChild(_preloader);
				
				TweenMax.to(_preloader, 1, {alpha:1, ease:Expo.easeOut, onComplete:addFlipBook});
				
			}
		}
		
		private function switchCategory(str:String):void {
			switch(str){
				case "category": 
					showPages(_covers, "category"); 
					break;
				case "pages": 
					showPages(_fb.pages, "pages");	
					break;		
				case "printer": 
					showPages(_fb.pages, "printer");	
					break;	
				case "pdf": 
					showPages(_fb.pages, "pdf");	
					break;		
				case "contact": 
					_cp.getChildByName("contact").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;	
				case "tell_a_friend": 
					_cp.getChildByName("tell").dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;												
			}			
		}		
		private function checkUrl(str:String):Boolean {
			var ar:Array = SWFAddress.getPathNames();
			
			if(str == String(ar[2])){
				return false;
			} else {
				return true;
			}
		}	
		private function uiInteractive(tmp:Boolean):void{
			if(_ssTimer && _ssTimer.running){
				_cp.mouseEnabled = true;
				_cp.mouseChildren = true;
				return;
			}
			
			if(_cp){
				_cp.mouseEnabled = tmp;
				_cp.mouseChildren = tmp;
			}
		}
		private function disableUi(e:CustomEvent):void {
			//trace("disable" + Math.random());
			if(_ssTimer && _ssTimer.running)
				uiInteractive(true);
			else
				uiInteractive(false);
			
			this.arrowsRemoveEvents();
			_fb.interactive(false);
		}
		private function enableUi(e:CustomEvent):void {
			//trace("enable" + Math.random());
			uiInteractive(true);
			this.arrowsAddEvents();
			_fb.interactive(true);
		}
		private function onResize(e:Event):void {  // on resize we set the x ad y value of each object on the stage.
			if(_fb != null  && this.contains(_fb) && _zoomed){
				var newScale:Number = (stage.stageWidth * 2) / (_fb.fbWidth - (int(_xml.flipbook[_book].@boarder) * 2));
				
				if(_fb.x > -100){
				//	trace("kill");
					TweenMax.killTweensOf(_fb);
					if(_fb.currentPage != -1){
						_fb.x = -int(_xml.flipbook[_book].@boarder) * newScale;
						_fb.y = (stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5;
						_fb.scaleY = _fb.scaleX = newScale;
					} else {
						_fb.x = -stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale);
						_fb.y = (stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5;
						_fb.scaleY = _fb.scaleX = newScale;		
					}
				} else {
				//	trace("kill");
					TweenMax.killTweensOf(_fb);
					_fb.x = -stage.stageWidth -(int(_xml.flipbook[_book].@boarder) * newScale)
					_fb.y = (stage.stageHeight - (_fb.fbHeight * newScale)) * 0.5;
					_fb.scaleY = _fb.scaleX = newScale;		
					
				}
				
				nextPage.y = (stage.stageHeight - nextPage.height) * 0.5;
				nextPage.x = (stage.stageWidth - nextPage.width);
				previewPage.y = (stage.stageHeight - previewPage.height) * 0.5;
				previewPage.x = nextPage.width;
				return;
			}
			if(_fb && this.contains(_fb)){
				if (stage.displayState == StageDisplayState.NORMAL) {
					if(_fb.getChildByName("goToPage"))
						_fb.getChildByName("goToPage").alpha = 1;
				}	
			}
			
			if(_fb != null  && this.contains(_fb) && !_fbDown){
				_fb.x = (stage.stageWidth - _fb.fbWidth) / 2; 
				_fb.y = ((stage.stageHeight - _fb.fbHeight) / 2)+25;
				previewPage.y = nextPage.y = (stage.stageHeight /2) - 30;
				previewPage.x = _fb.x - 10;
				nextPage.x = _fb.x + _fb.fbWidth +  10;
			}
			
			if(_resizeBg && stage){
			 	var ratio:Number = bg.height / bg.width;
				bg.width = stage.stageWidth;
				bg.height = bg.width * ratio;
				
				if(bg.height < stage.stageHeight){
					ratio = bg.width / bg.height;
					bg.height = stage.stageHeight;
					bg.width = bg.height * ratio;
				}
			}
			
			if(_sp && _cb != null && this.contains(_cb)){
				_cb.y = _sp.y - 100;
				_cb.x = (stage.stageWidth - _cb.width) / 2;
				_mask.x = (stage.stageWidth - _mask.width) / 2;
			}
			if(_copyright){
				_copyright.x = stage.stageWidth / 2;
				_copyright.y = stage.stageHeight - 25;
			}
			if(e != null)
				onResize(null);
		}
	}
}