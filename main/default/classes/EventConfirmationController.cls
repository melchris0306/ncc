/*******************************************************************************************
* @author: Jasmine Nguyen
* @created: 31-08-2020
* @description: Calls the helper to generates the wrapper that will be displayed in the table for Confirmation Emails
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*             No.   Date(dd-mm-yyy)   Author                Description
*             ----  ---------------   --------------------  ---------------------------------
* @version    1.0   05-09-2020        Jasmine Nguyen        Initial Creation
*			  2.0	05-09-2020		  Jasmine Nguyen		Added helper to abstract some data query from main controller
* 			  3.0	30-04-2022		  Paolo Quiambao		[CCN-1216] added Confirm All/Decline All logic
*********************************************************************************************/

public with sharing class EventConfirmationController {
    public String campaignMemberId;
    public List<EventConfirmationHelper.SessionWrapper> Sessions;

    public String campaignOwnerId {get;set;} 
    public String campaignId {get;set;}
    public String defined_format {get;set;} 
    public String FormattedDatetime;
    public String startOrEndDate {get; set;}
    public String timeOrDate {get; set;}
    public String confirmAllLink {get;set;} // Updated by PaoloQuiambao [ccneve1216dv] April302022
    public String declineAllLink {get;set;} // Updated by PaoloQuiambao [ccneve1216dv] April302022
    public Boolean showConfirmDeclineAllButton {get;set;} // Updated by PaoloQuiambao [ccneve1216dv] April302022

    public EventConfirmationController(){
    
    }
    
    public void setcampaignMemberId(String cpMemberId){
        campaignMemberId = cpMemberId;
        if (campaignMemberId != null){
            EventConfirmationHelper.EventConfirmationWrapper returnedEventConfirmationWrapper = EventConfirmationHelper.getSessionsDetails(campaignMemberId); // Updated by PaoloQuiambao [ccneve1216dv] April302022
            List<EventConfirmationHelper.SessionWrapper> returnedSessions = returnedEventConfirmationWrapper.sessionList != null ? returnedEventConfirmationWrapper.sessionList : new List<EventConfirmationHelper.SessionWrapper>(); // Updated by PaoloQuiambao [ccneve1216dv] April302022
            if (returnedSessions.size() > 0) Sessions = returnedSessions;   
            confirmAllLink = returnedEventConfirmationWrapper.confirmAllLink; // Updated by PaoloQuiambao [ccneve1216dv] April302022
            declineAllLink = returnedEventConfirmationWrapper.declineAllLink; // Updated by PaoloQuiambao [ccneve1216dv] April302022
            showConfirmDeclineAllButton = returnedEventConfirmationWrapper.showConfirmDeclineAllButton; // Updated by PaoloQuiambao [ccneve1216dv] April302022
        }
    }

    public String getcampaignMemberId(){
        return campaignMemberId; 
    }

 
	public List<EventConfirmationHelper.SessionWrapper> getSessions() {
		return Sessions;
    }

    // Format event Start Time based on event's owner timezone
    public String getFormattedDatetime() {
        return EventConfirmationHelper.getFormattedDateTimeHelper(campaignOwnerId, campaignId, startOrEndDate, defined_format, timeOrDate);
    }
}