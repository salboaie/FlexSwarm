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
		protected var _swarmingData:Object;		
		
		/************************************************************************************************************************************
		 *  Functions
		 ***********************************************************************************************************************************/
		
		public function SwarmEvent(swarmingData:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_swarmingData = swarmingData;			
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get swarmingData():Object
		{
			return _swarmingData;
		}
		
			
		//___________________________________________________________________________________________________________________________________
		
		public function get swarmingName():String
		{
			return _swarmingData.swarmingName;
		}
		
		//___________________________________________________________________________________________________________________________________
		
		public function get swarmingPhase():String
		{
			return _swarmingData.currentPhase;
		}
		//___________________________________________________________________________________________________________________________________

		override public function clone():Event
		{
			return new SwarmEvent(_swarmingData,bubbles,cancelable);
		}
		
		//___________________________________________________________________________________________________________________________________
		
	}
}