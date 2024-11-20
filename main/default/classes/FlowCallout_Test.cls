@isTest
public with sharing class FlowCallout_Test {

	@TestSetup
	static void makeData(){
        
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
        
		Test.setMock(HTTPCalloutMock.class, new ValidCallout());
		Event__c newCampaign = TestFactory.createEvent('Test Campaign');
		Survey__c newSurvey = TestFactory.createSurvey(newCampaign.Id, 'Test Survey');
		Survey_Question__c sq = TestFactory.createSurveyQuestion(newSurvey.Id, 'What is your name?', 'Text', 1);
		Account newPersonAccount = TestFactory.createPersonAccount('John', 'Doe','j.doe@gmail.com');
		Contact c = TestFactory.createContact('John', 'Doe', 'john.doe@gmail.com');
		String contactStr = '{"Contact|FirstName":"John","Contact|LastName":"Doe","Contact|Email":"john.doe@gmail.com"}';
		String resultStr = '{"' + sq.Id + '":{"Question":"Select a value between 1 to 5","Answer":"4"}}';
		Event__c cp = [SELECT Id, Event_Id__c FROM Event__c WHERE ID = :newCampaign.Id LIMIT 1];
		
        //replaced call from CCESurveyController to avoid dependency to another class that isn't a test helper class
        Survey_Response__c surveyResp = TestFactory.createSurveyResponse(cp.Id, newSurvey.Id, newPersonAccount.Id);
        TestFactory.createSurveyAnswer(surveyResp.Id, 'What is your name?', 'Test Answer');
	}

	@isTest
	static void test_program_flow(){
		List<Survey_Answer__c> answers = [
			SELECT Id, 
			Name, 
			Survey_Response__c, 
			Answer__c, 
			Question_Sorting_Order__c, 
			Question_Type__c, 
			Question__c, 
			Survey_Question__c 
			FROM Survey_Answer__c
		];
		Test.setMock(HTTPCalloutMock.class, new ValidCallout());
		Boolean hasErrors = false;
		Test.startTest();
			try {
				FlowCallout.doCallout(answers);
			} catch (Exception e){
				hasErrors = true;
			}
		Test.stopTest();	
		System.assert(!hasErrors, 'Error encountered when executing a flow callout instance');
	}

	class TestErrorCallout extends FlowCallout.ApexCallout{
		protected String error = 'wont perform a callout';
		public TestErrorCallout(){
			super(JSON.serializePretty(new Map<String, Object>{'fail'=>'fail'}), 'default endpoint');
		}
		public override void callout(){
			String outcome = 'do nothing';
		}

		public string getErrorMessage(){
			return this.error;
		}
	}

	@isTest
	static void test_error_callout(){
		// mock ApexCallout
		FlowCallout.ApexCallout tc = new TestErrorCallout();
		Test.startTest();
			tc.callout();
		Test.stopTest();
		System.assertEquals('wont perform a callout', ((TestErrorCallout)tc).getErrorMessage(), 'Error message is different from what is expected');
		System.assert(tc instanceof TestErrorCallout, 'test callout was not an instance of flow callout');
	}

	@isTest
	static void test_valid_callout(){
		FlowCallout.ApexCallout tc = new FlowCallout.FireAndForget('payload', 'endpoint');
		Boolean hasErrors = false;
		Test.setMock(HTTPCalloutMock.class, new ValidCallout());
		Test.startTest();
			try {
				tc.callout();
			} catch (Exception e){
				hasErrors = true;
			}
		Test.stopTest();
		System.assert(!hasErrors, 'Encountered error while mocking a valid callout');
		System.assert(tc instanceOf FlowCallout.FireAndForget, 'tc instance was not FireAndForget, instantiated into a different object');
	}
	@testVisible
	public class ValidCallout implements HTTPCalloutMock{
		public HTTPResponse respond(HttpRequest req){
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(JSON.serializePretty(new Map<String, Object>{'message'=>'jobs enqueued'}));
			res.setStatusCode(200);
			return res;
		}
	}

	@isTest
	static void test_no_filter(){
		Flow_Callout_Config__mdt config = [
			SELECT Callout_Endpoint__c,
			Fields__c, 
			Filter_Object__r.QualifiedApiName,
			Filter_Object_Condition__c,
			Filter_Object_Field__r.QualifiedApiName,
			Object_Field_Qualifier__r.QualifiedApiName
			FROM Flow_Callout_Config__mdt 
			WHERE Object_Type__r.QualifiedApiName = 'Survey_Answer__c' 
			LIMIT 1
		];
		Flow_Callout_Config__mdt cloned = config.clone(false, false, false, false);
		cloned.Object_Field_Qualifier__c = null;
		cloned.Filter_Object_Condition__c = null;
		List<sObject> qualifiers = new List<sObject>();
		List<sObject> records = new List<sObject>();
		String outcome;
		Test.startTest();
			outcome = FlowCallout.applyFilterAndQualifier(cloned, records, qualifiers);
		Test.stopTest();
		System.assertEquals('', outcome, 'outcome should be blank for no filter records');
		System.assertEquals(0, qualifiers.size(), 'qualifiers should not be populated when there is no filter');
		System.assertEquals(null, cloned.Object_Field_Qualifier__c, 'passed metadata should not contain a qualifier when no filtering is needed');
	}
}