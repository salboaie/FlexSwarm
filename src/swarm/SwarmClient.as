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
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	public class SwarmClient extends EventDispatcher
	{
		/************************************************************************************************************************************
		 *  Const
		 ***********************************************************************************************************************************/
		public static var LOGIN_SWORMING_NAME:String = 'login.js';
		public static var LOGIN_CTOR_NAME:String 	 = 'start';
		public static var IDENTITY_COMMAND:String 	 = 'identity';
		
		public static const WAITING_FOR_IDENTITY:uint = 0;
		public static const WAITING_FOR_LOGIN:uint 	  = 1;
		public static const WAITING_FOR_DATA:uint 	  = 2;
		
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
		protected var _clientState  :uint;			
		
		protected var _securityErrorHandler	: Function = null;
		protected var _onErrorHandler 		: Function = null;
		protected var _pendingCmds			: Array;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmClient( host:String, port:uint, 
									 userId:String, secretPass:String, 
									 securityErrorFunction:Function = null,
									 errorFunction:Function = null,
									 loginCtor:String = "start")
		{
			super(null);
			
			_host 			= host;
			_port 			= port;
			_loginOk 		= false;
			_pendingCmds 	= new Array();
			
			_onErrorHandler 	  = errorFunction;
			_securityErrorHandler = securityErrorFunction;
			
			_callBacks 	= new Dictionary();
			_jsonUtil  	= new SwarmJsonUtil(waitingForIdentity);
			
			_userId 	= userId;
			_pass		= secretPass;
			_loginCtor 	= loginCtor;
			_sessionId  = null;
			
			createSocket();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get sessionId():String
		{
			return _sessionId;
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
		
		protected function socket_onConnect(event:Event):void
		{}	
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onStreamData(event:ProgressEvent):void
		{
			var streamMessage:String =_socket.readUTFBytes(_socket.bytesAvailable); 
			
			_jsonUtil.parseStream( _socket.readUTFBytes(_socket.bytesAvailable) );
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onSecurityError(event:SecurityErrorEvent):void
		{
			if(_securityErrorHandler != null)
			{
				_securityErrorHandler(event);
			}
			else 
			{
				Alert.show("Connection to server failed. Check crosdomain.xml configuration.");	
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onError(event:IOErrorEvent):void
		{
			if(_onErrorHandler != null)
			{
				_onErrorHandler(event);
			}
			else 
			{
				Alert.show("Connection to server failed");	
			}
			
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function waitingForIdentity( data:Object ):void
		{
 			if ( _clientState == WAITING_FOR_IDENTITY && data.command == IDENTITY_COMMAND ) 
			{
				_clientState	   = WAITING_FOR_LOGIN;
				_jsonUtil.callBack = waitingForLogin;
				_sessionId		   = data.sessionId;				
				
				var cmd:Object = 
					{
					swarmingName     : LOGIN_SWORMING_NAME,
					command          : LOGIN_CTOR_NAME,
					ctor		 	 : _loginCtor,
					commandArguments : [_sessionId, _userId, _pass]
					};
				
				writeObject(cmd);
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function waitingForLogin( data:Object ):void
		{
			var i:int;
			var command:Object;
			
			if( _clientState == WAITING_FOR_LOGIN )
			{	
				_loginOk = data.isOk;
				
				if ( _loginOk )
				{
					_clientState 	   = WAITING_FOR_DATA;
					_jsonUtil.callBack = socket_onDataReady;
					_loginOk 		   = true;
					
					for (i = 0; i < _pendingCmds.length; i++) 
					{
						command = _pendingCmds[i];
						command.sessionId = _sessionId;
						writeObject(command);
					}	
					
					_pendingCmds = null;
				}
				else
				{
					Alert.show("Login failed !","Login failed : authorisationToken:["+data.authorisationToken+"] userId:["+data.userId+"]");
				}
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onDataReady( data:Object ):void
		{
			if ( _clientState == WAITING_FOR_DATA )
			{
				dispatchEvent( new SwarmEvent(data) );			
				callSwarmingCallBack( data.swarmingName, data );
			}
						
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function startSwarm (swarmName:String, ctroName:String, ... args):Object 
		{
			var cmd:Object = 
				{
					sessionId        : _sessionId,
					swarmingName     : swarmName,
					command          : LOGIN_CTOR_NAME,
					ctor             : ctroName,
					commandArguments : args
				};
			
			if( _loginOk == true ) 
			{
				writeObject(cmd);
			}
			else 
			{
				_pendingCmds.push(cmd);
			}
			
			return cmd;
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