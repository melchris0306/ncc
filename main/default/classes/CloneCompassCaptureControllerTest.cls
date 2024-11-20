@isTest
public class CloneCompassCaptureControllerTest {
	@isTest
    public static void test_doClone(){
        Compass_Capture__c compassCapture = new Compass_Capture__c();
        Insert compassCapture;
        
        Impact_Capture__c impactCapture = new Impact_Capture__c();
        impactCapture.Capture_ID__c = compassCapture.Id;
        Insert impactCapture;
        
        CloneCompassCaptureController.doClone(compassCapture.Id, 'Compass_Capture__c');
        
        system.assertEquals(2, [SELECT ID FROM Compass_Capture__c].size());
    }
}