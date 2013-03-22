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
		public static var LOGIN_CTOR_NAME:String 	 = 'authenticate';
		public static var IDENTITY_COMMAND:String 	 = 'identity';
		
		public static const WAITING_FOR_IDENTITY:uint = 0;
		public static const WAITING_FOR_LOGIN:uint 	  = 1;
		public static const WAITING_FOR_DATA:uint 	  = 2;
		
		public static const API_VERSION:String = '1.1';
		
		/************************************************************************************************************************************
		 *  Variables
		 ***********************************************************************************************************************************/
		protected var _jsonUtil		: SwarmJsonUtil;
		protected var _callBacks	: Dictionary;
		protected var _socket		: Socket;
		protected var _host			: String;
		protected var _port			: uint;
		
		protected var _userId		: String;
		protected var _authToken  	: String;
		protected var _loginCtor  	: String;
		protected var _loginOk  	: Boolean;
		
		protected var _outletId 	:String;			
		protected var _sessionId	:String;			
		protected var _apiVersion 	:String;			
		protected var _clientState  :uint;			

		protected var _securityErrorHandler	: Function = null;
		protected var _onErrorHandler 		: Function = null;
		protected var _pendingCmds			: Array;
		
		protected var _tenantId:String;
		
		protected var _socketNeedConnect:Boolean       = true;
		protected var _socketPendingConnect:Boolean    = false;
		protected var _socketConnectionTryCounter:uint = 0;
		protected var _reconnectionAttempts:uint = 0;
		protected var _reconnectionAttemptsWindowVisible:Boolean = false;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmClient( host:String, port:uint, 
									 userId:String, authToken:String,
									 tenantId:String,
									 securityErrorFunction:Function = null,
									 errorFunction:Function = null,
									 loginCtor:String = "authenticate")
		{
			super(null);
			
			_tenantId       = tenantId;
			_host 			= host;
			_port 			= port;
			_loginOk 		= false;
			_pendingCmds 	= new Array();
			
			_onErrorHandler 	  = errorFunction;
			_securityErrorHandler = securityErrorFunction;
			
			_callBacks 	= new Dictionary();
			_jsonUtil  	= new SwarmJsonUtil(waitingForIdentity);
			_jsonUtil.addEventListener(SwarmEvent.ON_ERROR, jsonUtil_parseErrorHandler);
			
			_userId 	= userId;
			_authToken	= authToken;
			_loginCtor 	= loginCtor;
			_sessionId  = null;
			
			_socketNeedConnect    = true;
			_socketPendingConnect = false;
			
			createSocket();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function jsonUtil_parseErrorHandler(event:SwarmEvent):void
		{
			dispatchEvent( event );
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get outletId():String
		{
			return _outletId;
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
			_socket.addEventListener( Event.CLOSE,                       socket_onDisconect);
			_socket.addEventListener( ProgressEvent.SOCKET_DATA,         socket_onStreamData);
			_socket.addEventListener( IOErrorEvent.IO_ERROR,             socket_onError);
			_socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, socket_onSecurityError);
			
			connect();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onDisconect(event:Event):void
		{
			if ( _clientState == WAITING_FOR_LOGIN )
			{
				dispatchEvent(new Event(Event.CLOSE));			
			}
			else
			{
				socketWentDown();
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socketWentDown():void
		{
			_socketNeedConnect    = true;
			_socketPendingConnect = false;
			connect();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function isSocketAlive():Boolean
		{
			return !_socketNeedConnect;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onConnect(event:Event):void
		{
			_socketNeedConnect          = false;
			_socketPendingConnect       = false;	 
			_socketConnectionTryCounter = 0;
			
			if ( _reconnectionAttempts )
			{
				_reconnectionAttempts = 0;
				Alert.show("Server is up and running !");
			}
			
			getIdentity();
			
			dispatchEvent(new Event(Event.CONNECT));
		}	
		
		//___________________________________________________________________________________________________________________________________
		
		protected function initSocketClient():void
		{
			_loginOk           = false;
			_sessionId   	   = null;
			_clientState 	   = WAITING_FOR_IDENTITY;
			_jsonUtil.callBack = waitingForIdentity;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function connect():void
		{
			if ( _socketConnectionTryCounter >= 3 )
			{
				if ( !_reconnectionAttemptsWindowVisible )
				{
					_reconnectionAttempts++;
					_reconnectionAttemptsWindowVisible = true;
					Alert.show("Connection to server failed. Trying to connect "+_socketConnectionTryCounter+" times. \n RECONNECT ???","Server is down!",Alert.YES,null,onServerDownAlerHandler);	
				}
				return;	
			}
			
			if ( _socketNeedConnect && !_socketPendingConnect )
			{
				_socketPendingConnect = true;
				_socketConnectionTryCounter++;
				initSocketClient();
				_socket.connect(_host,_port);
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		private function onServerDownAlerHandler(event:Event):void
		{
			_reconnectionAttempts = 0;
			_reconnectionAttemptsWindowVisible = false;
			_socketNeedConnect = true;
			_socketPendingConnect = false;
			connect();
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onStreamData(event:ProgressEvent):void
		{
			if ( !isSocketAlive() )
			{
				Alert.show("Socket is down !","Error");
				return;
			}
			
			_jsonUtil.parseStream( _socket.readUTFBytes(_socket.bytesAvailable) );
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function socket_onSecurityError(event:SecurityErrorEvent):void
		{
			socketWentDown();
			
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
			socketWentDown();
			
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
		
		protected function getIdentity():void
		{
			var cmd:Object =
				{
					meta: {
						swarmingName     : LOGIN_SWORMING_NAME,
						command          : 'getIdentity',
						ctor		 	 : _loginCtor,
						tenantId         : _tenantId,                        
						commandArguments : [_sessionId, _userId, _authToken]
					}
					
				};
			
			writeObject(cmd);
		}
		
		//___________________________________________________________________________________________________________________________________
		
		protected function waitingForIdentity( data:Object ):void
		{
 			if ( _clientState == WAITING_FOR_IDENTITY && data.meta && data.meta.command == IDENTITY_COMMAND )
			{
				_clientState	   = WAITING_FOR_LOGIN;
				_jsonUtil.callBack = waitingForLogin;
				_sessionId		   = data.meta.sessionId;
				_apiVersion		   = data.meta.apiVersion;
				
				if ( API_VERSION != _apiVersion )
				{
					Alert.show("Api version don't match !","Api version error");					
				}
				
				var cmd:Object =
                {
					meta: {
                        swarmingName     : LOGIN_SWORMING_NAME,
                        command          : 'start',
                        ctor		 	 : _loginCtor,
                        tenantId         : _tenantId,                        
						commandArguments : [_sessionId, _userId, _authToken]
                    }

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
					_outletId		   = data.meta.outletId;
                    _sessionId		   = data.meta.sessionId;
					_clientState 	   = WAITING_FOR_DATA;
					_jsonUtil.callBack = socket_onDataReady;
					_loginOk 		   = true;
					
					for (i = 0; _pendingCmds && i < _pendingCmds.length; i++) 
					{
						command = _pendingCmds[i];
						command.meta.sessionId = _sessionId;
						command.meta.outletId = _outletId;
						writeObject(command);
					}	
					
					_pendingCmds = [];
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
                if( data && data.meta && data.meta.changeSessionId == true) {
                    _sessionId = data.meta.sessionId;
                }
				dispatchEvent( new SwarmEvent(SwarmEvent.ON_DATA,data) );			
				callSwarmingCallBack( data.meta.swarmingName, data );
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function startSwarm (swarmName:String, ctroName:String, ... args):Object 
		{
			var cmd:Object = 
				{
					meta:{
                        sessionId        : _sessionId,
                        swarmingName     : swarmName,
                        tenantId         : _tenantId,
						outletId         : _outletId,
                        command          : "start",
                        ctor             : ctroName,
                        commandArguments : args
                    }
				};
			
			if ( !isSocketAlive() )
			{				
				connect();
			}
			
			
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
			if ( !isSocketAlive() )
			{
				Alert.show("Socket is down !","Error");
				return;
			}
			
			if ( _socket )
			{
				_jsonUtil.writeObject( _socket, value );
			}
		}
		
		//___________________________________________________________________________________________________________________________________
		
	}
}