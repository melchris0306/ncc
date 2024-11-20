@isTest
public with sharing class TriggerHandler_Test {
	
	private class TestTriggerHandler extends TriggerHandler {
		public TriggerOperation Method { get; private set;}

		@testVisible
		protected override void beforeInsert(List<SObject> newRecords) {
			this.Method = TriggerOperation.BEFORE_INSERT;
		}
		@testVisible
		protected override void beforeUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
			this.Method = TriggerOperation.BEFORE_UPDATE;
		}
		@testVisible
		protected override void beforeDelete(Map<Id, SObject> deletedRecordsMap) {
			this.Method = TriggerOperation.BEFORE_DELETE;
		}
		@testVisible
		protected override void afterInsert(Map<Id, SObject> newRecordsMap) {
			this.Method = TriggerOperation.AFTER_INSERT;
		}
		@testVisible
		protected override void afterUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
			this.Method = TriggerOperation.AFTER_UPDATE;
		}
		@testVisible
		protected override void afterDelete(Map<Id, SObject> deletedRecordsMap) {
			this.Method = TriggerOperation.AFTER_DELETE;
		}
		@testVisible
		protected override void afterUndelete(Map<Id, SObject> undeletedRecordsMap) {
			this.Method = TriggerOperation.AFTER_UNDELETE;
		}
	}
	@isTest
	static void it_should_perform_before_insert() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.BEFORE_INSERT;

		testHandler.execute();

		System.assertEquals(TriggerOperation.BEFORE_INSERT, testHandler.Method);
	}

	@isTest
	static void it_should_perform_before_update() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.BEFORE_UPDATE;

		testHandler.execute();

		System.assertEquals(TriggerOperation.BEFORE_UPDATE, testHandler.Method);
	}

	@isTest
	static void it_should_perform_before_delete() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.BEFORE_DELETE;

		testHandler.execute();

		System.assertEquals(TriggerOperation.BEFORE_DELETE, testHandler.Method);
	}

	@isTest
	static void it_should_perform_after_insert() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.AFTER_INSERT;

		testHandler.execute();

		System.assertEquals(TriggerOperation.AFTER_INSERT, testHandler.Method);
	}

	@isTest
	static void it_should_perform_after_update() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.AFTER_UPDATE;

		testHandler.execute();

		System.assertEquals(TriggerOperation.AFTER_UPDATE, testHandler.Method);
	}

	@isTest
	static void it_should_perform_after_delete() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.AFTER_DELETE;

		testHandler.execute();

		System.assertEquals(TriggerOperation.AFTER_DELETE, testHandler.Method);
	}

	@isTest
	static void it_should_perform_after_undelete() {
		TestTriggerHandler testHandler = new TestTriggerHandler();
		testHandler.triggerContext = TriggerOperation.AFTER_UNDELETE;

		testHandler.execute();

		System.assertEquals(TriggerOperation.AFTER_UNDELETE, testHandler.Method);
	}

	@isTest
	static void program_flow(){
		TriggerHandler testHandler = new TriggerHandler();
		testHandler.triggerContext = TriggerOperation.BEFORE_INSERT;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.BEFORE_INSERT);
        
		testHandler.triggerContext = TriggerOperation.BEFORE_UPDATE;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.BEFORE_UPDATE);
        
		testHandler.triggerContext = TriggerOperation.BEFORE_DELETE;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.BEFORE_DELETE);
        
		testHandler.triggerContext = TriggerOperation.AFTER_INSERT;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.AFTER_INSERT);
        
		testHandler.triggerContext = TriggerOperation.AFTER_UPDATE;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.AFTER_UPDATE);
        
		testHandler.triggerContext = TriggerOperation.AFTER_DELETE;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.AFTER_DELETE);
        
		testHandler.triggerContext = TriggerOperation.AFTER_UNDELETE;
		testHandler.execute();
        system.assertEquals(testHandler.triggerContext, TriggerOperation.AFTER_UNDELETE);
		// List<Account> accList = new List<Account>();
		// for (Integer i = 0; i < 2; i ++){
		// 	accList.add(new Account(Name='Test'+i));
		// }
		// insert accList;
		// for (Integer i = 0; i < 2; i ++){
		// 	accList[i].Name = 'Modified'+i;
		// }
		// update accList;
		// List<sObject> accounts = testHandler.getUpdatedRecordsWithChangedField(Account.Name);
		// for (sObject so : accounts){
		// 	System.assert(so instanceOf Account, 'the handler returned a different object instance');
		// }
	}

}