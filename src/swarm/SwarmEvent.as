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
	
	public class SwarmEvent extends Event
	{
		/************************************************************************************************************************************
		 *  Const
		 ***********************************************************************************************************************************/
		public static const ON_DATA:String='onData';
		
		/************************************************************************************************************************************
		 *  Vars
		 ***********************************************************************************************************************************/
		protected var _swormingData:Object;
		protected var _swormingName:String;
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmEvent(type:String, swormingName:String, swormingData:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_swormingData = swormingData;
			_swormingName = swormingName;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get swormingData():Object
		{
			return _swormingData;
		}
		
		//___________________________________________________________________________________________________________________________________

		public function get swormingName():String
		{
			return _swormingName;
		}
		
		//___________________________________________________________________________________________________________________________________

		override public function clone():Event
		{
			return new SwarmEvent(type,_swormingName,_swormingData,bubbles,cancelable);
		}
		
		//___________________________________________________________________________________________________________________________________
		
	}
}