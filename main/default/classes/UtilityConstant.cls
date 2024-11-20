/**
* @description Utility Constant Class for Strings
* @revision
*			02.25.2021 - Afrancisco - Initial creation
			09.01.2021 - Paolo Quiambao - Added PARTICIPANT_STATUS_RESPONDED and EMAIL_TEMPLATE_REGISTRATION_NAME
            01.06.2022 - DinoBrinas - [CCN1036] Added Session Participant Role Names and Status Report 
            
**/
global class UtilityConstant {
	public static String PARTICIPANT_STATUS_INVITED = 'Invited';
    public static String PARTICIPANT_STATUS_RESPONDED = 'Responded';
    public static String PARTICIPANT_STATUS_REGISTERED = 'Registered';
   public static String PARTICIPANT_STATUS_IN_PROGRESS = 'In Progress'; //XR Mar 22, 2022
    
    public static String EMAIL_TEMPLATE_INVITATION_NAME = 'Event_Invitation_Template';
    public static String EMAIL_TEMPLATE_CONFIRMATION_NAME = 'Event_Confirmation_Template';
    public static String EMAIL_TEMPLATE_REGISTRATION_NAME = 'Event_Registration_Notification';
    // Added by DinoBtinas [CCN1036] 
    public static String SESSIONPARTICIPANT_ROLENAME_SUPERUSERFACILITATOR  = 'Super User Facilitator';
    public static String SESSIONPARTICIPANT_ROLENAME_WALKIN = 'Walk-In';
    public static String SESSIONPARTICIPANT_ROLENAME_OBSERVER = 'Observer';
    public static String SESSIONPARTICIPANT_ROLENAME_PEEREXPERTFACILITATOR = 'Peer Expert Facilitator';
    public static String SESSIONPARTICIPANT_STATUS_ATTENDED = 'Attended';
    public static String SESSIONPARTICIPANT_STATUS_REGISTERED = 'Registered';
    public static String STATUSREPORT_ERRORMSG_SESSIONALOCATION01 = 'Please select session location available on above event and status report date';
    public static String STATUSREPORT_ERRORMSG_SESSIONALOCATION02 = 'Please select session location available on above event from';

}