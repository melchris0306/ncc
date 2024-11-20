@isTest
public class OutreachNotificationHistoryScheduleTest {
	@isTest
    public static void OutreachNotificationHistoryScheduleTest() {
        Test.startTest();
            OutreachNotificationHistorySchedule onhs = new OutreachNotificationHistorySchedule();
            String sch = '0 0 6 * * ?';
            String jobId = system.schedule('Outreach Notification History Batch Job', sch, onhs);
    
            CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        	System.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
    }
}