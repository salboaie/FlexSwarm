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
	
	import mx.controls.Alert;
	import mx.utils.UIDUtil;
	
	public class SwarmClient extends EventDispatcher
	{
		/************************************************************************************************************************************
		 *  Const
		 ***********************************************************************************************************************************/
		/************************************************************************************************************************************
		 *  Variables
		 ***********************************************************************************************************************************/
		protected var _jsonUtil		: SwarmJsonUtil;
		protected var _callBacks	: Dictionary;
		protected var _socket		: Socket;
		protected var _host			: String;
		protected var _port			: uint;
		
		protected var _userId		: String;
		protected var _pass  		: String;
		protected var _loginCtor  	: String;
		protected var _loginOk  	: Boolean;
		
		protected var _sessionId	:String;			
		
		protected var _securityErrFunc 	: Function = null;
		protected var _onErrFunc 		: Function = null;
		protected var pendingCmds		: Array;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmClient( host:String, port:uint, userId:String, 
									 secretPass:String, 
									 securityErrorFunction:Function = null,
									 errorFunction:Function = null,
									 loginCtor:String = "start")
		{
			super(null);
			_loginOk 	= false;
			pendingCmds = new Array();
			_onErrFunc 	= errorFunction;
			_securityErrFunc = securityErrorFunction;
			_host 		= host;
			_port 		= port;
			
			_callBacks 	= new Dictionary();
			_jsonUtil  	= new SwarmJsonUtil(socket_onDataReady);
			
			_userId 	= userId;
			_pass		= secretPass;
			_loginCtor 	= loginCtor;
			_sessionId = UIDUtil.createUID();
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
			_socket.connect(_host,_port);
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onSecurityError(event:SecurityErrorEvent):void
		{
			if(_securityErrFunc != null)
			{
				_securityErrFunc(event);
			}
			else 
			{
				Alert.show("Connection to server failed. Check crosdomain.xml configuration.");	
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onError(event:IOErrorEvent):void
		{
			if(_onErrFunc != null)
			{
				_onErrFunc(event);
			}
			else 
			{
				Alert.show("Connection to server failed");	
			}
			
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
			//start login 
			var cmd:* = {
				sessionId        : _sessionId,
				swarmingName     : "login.js",
				command          : "start",
				ctor		 	 : _loginCtor,
				commandArguments : [_sessionId, _userId, _pass]
			};
			writeObject(cmd);
		}		
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onDataReady( data:Object ):void
		{
			var event:SwarmEvent = new SwarmEvent( data );
			dispatchEvent( event );			
			callSwarmingCallBack( data.swarmingName, data );
			
			if(_loginOk != true) {			
				_loginOk = true;
				//if was not allready closed,it should be a successful login
				for (var i:int = 0; i < pendingCmds.length; i++) {
					writeObject(pendingCmds[i]);					
				}				
				pendingCmds = null;
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		public function startSwarm (swarmName:String, ctroName:String):void 
		{
			var args:Array = Array.prototype.slice.call(arguments,2);
			
			var cmd:* = 
				{
					sessionId        : _sessionId,
					swarmingName     : swarmName,
					command          : "start",
					ctor             : ctroName,
					commandArguments : args
				};
			if(_loginOk == true) 
			{
				writeObject(cmd);
			}
			else 
			{
				pendingCmds.push(cmd);
			}
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