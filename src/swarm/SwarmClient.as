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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.Dictionary;
	
	public class SwarmClient extends EventDispatcher
	{
		/************************************************************************************************************************************
		 *  Const
		 ***********************************************************************************************************************************/
		/************************************************************************************************************************************
		 *  Variables
		 ***********************************************************************************************************************************/
		protected var _jsonUtil:SwarmJsonUtil;
		protected var _callBacks:Dictionary;
		protected var _socket:Socket;
		protected var _host:String;
		protected var _port:uint;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmClient( host:String, port:uint )
		{
			super(null);
			
			_host = host;
			_port = port;
			
			_callBacks = new Dictionary();
			_jsonUtil  = new SwarmJsonUtil(socket_onDataReady);
			
			createSocket();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function createSocket():void
		{
			_socket = new Socket();
			_socket.addEventListener( Event.CONNECT,                     socket_onConnect);
			_socket.addEventListener( ProgressEvent.SOCKET_DATA,         socket_onStreamData);
			_socket.addEventListener( IOErrorEvent.IO_ERROR,             socket_onError);
			_socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, socket_onSecurityError);
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onSecurityError(event:SecurityErrorEvent):void
		{
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onError(event:IOErrorEvent):void
		{
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onStreamData(event:ProgressEvent):void
		{
			var streamMessage:String =_socket.readUTFBytes(_socket.bytesAvailable); 
			_jsonUtil.parseStream( streamMessage );
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onConnect(event:Event):void
		{
		}		
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onDataReady( data:Object ):void
		{
			var event:SwarmEvent = new SwarmEvent( SwarmEvent.ON_DATA, data.swarmingName, data );
				dispatchEvent( event );
			
			callSwarmingCallBack( data.swarmingName, data );
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function callSwarmingCallBack( swarmingName:String, data:Object ):void
		{
			var callback:Function = _callBacks[swarmingName];
			
			if ( callback != null )
			{
				callback(data);
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function addCallback( swarmingName:String, callback:Function ):void
		{
			_callBacks[swarmingName] = callback;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function connect():void
		{
			_socket.connect(_host,_port);
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function writeObject( value:Object ):void
		{
			if ( _socket )
			{
				_jsonUtil.writeObject( _socket, value );
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
	}
}