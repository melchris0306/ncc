trigger StatusReportTrigger on Status_Report__c (before update) {
   
    system.debug('Hi');
    StatusReportUtilityClass.updateParkingLotsAndSurveys(Trigger.New);
    StatusReportUtilityClass.UpdateEmailBody(Trigger.New);

}