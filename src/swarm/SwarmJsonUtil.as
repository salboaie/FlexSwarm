/**
 
 Copyright (c) 2012  Axiologic SaaS SRL,Iasi,Romania
 All Rights Reserved 
 This file is part of Quark Framework. (Licensed under a comercial license)
 This product is protected by copyright and distributed under
 licenses restricting copying, distribution and decompilation.
 
 (C) Axiologic SaaS. Iasi,Romania 	
 Quark Framework class
 
 Author MAC
 
 ***/

package swarm
{
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	
	import mx.controls.Alert;

	public class SwarmJsonUtil extends EventDispatcher
	{
		/************************************************************************************************************************************
		 *  Const
		 ***********************************************************************************************************************************/
		protected static const READ_SIZE:uint				 = 1;
		protected static const READ_JSON:uint				 = 3;
		protected static const JSONMAXSIZE_CHARS_HEADER:uint = 11;

		/************************************************************************************************************************************
		 *  Variables
		 ***********************************************************************************************************************************/
		protected var _state:uint	 = READ_SIZE;
		protected var _buffer:String = "";
		protected var _nextSize:uint = 0;
		protected var _callBack:Function;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmJsonUtil( callBack:Function )
		{
			_callBack = callBack;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get callBack():Function
		{
			return _callBack;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function set callBack(value:Function):void
		{
			_callBack = value;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function parseStream( data:String ):void
		{
			var doAgain:Boolean = true;
			var jsonString:String;
			var jsonObject:Object;
			
			_buffer += data;
			
			while(doAgain)
			{
				doAgain = false;
				if( _state == READ_SIZE)
				{
					if(_buffer.length >= JSONMAXSIZE_CHARS_HEADER)
					{
						_nextSize = parseInt(_buffer.substr(0,JSONMAXSIZE_CHARS_HEADER));
						_buffer   = _buffer.substring(JSONMAXSIZE_CHARS_HEADER);
						_state    = READ_JSON;
					}
				}
				
				if( _state == READ_JSON )
				{
					if(_buffer.length >= _nextSize)
					{
						jsonString = _buffer.substr(0,_nextSize);
						try
						{
							jsonObject = JSON.parse(jsonString);
						} 
						catch(error:Error) 
						{
							onError( error );
							_buffer = '';
							return;
						}
						
						_callBack(jsonObject);
						_buffer = _buffer.substring(_nextSize+1); 
						doAgain = true;
						_state = READ_SIZE;
					}
				}
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function writeObject(socket:Socket,object:Object):void
		{
			var objectStringified:String=JSON.stringify(object);
			
			writeSizedString (socket, objectStringified);
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function writeSizedString(socket:Socket,objectStringified:String):void
		{ 					
			var messageForSocket:String = decimalToHex(objectStringified.length)+'\n'+objectStringified+'\n';
			
			socket.writeUTFBytes( messageForSocket );
			socket.flush();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function decimalToHex(dataLength:Number, padding:uint = 8):String 
		{
			var hex:String = dataLength.toString(16)
				
			while (hex.length < padding) 
			{
				hex = "0" + hex;
			}
			
			return "0x"+hex;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function onError(error:Error):void
		{
			var errorObject:Object = {};
				errorObject.error = error;
				errorObject.buffer = _buffer;
				
			dispatchEvent( new SwarmEvent(SwarmEvent.ON_ERROR, errorObject));
		}
		
		//___________________________________________________________________________________________________________________________________
		
	}
}