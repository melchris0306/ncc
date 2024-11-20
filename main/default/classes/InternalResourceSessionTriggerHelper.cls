/******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  20-06-2022                   JC Espino        [CCN-EVE-3072-DV] Intial Version. Helper Class for InternalResourceSessionTriggerHandler.cls
    * @version   1.3  11-29-2023                   Rexie David      [CCN-EVE-3566-DV] Meeting Reminder Enhancement
    ******************************************************************************/
public without sharing class InternalResourceSessionTriggerHelper {

    public static void sendCalendarInvites(Set<Id> internalResourceIds) {
        Map<Id, Internal_Resource_Session__c> resourceMap = new Map<Id, Internal_Resource_Session__c>(
            [SELECT Id, 
                    Is_Eligible_For_Calendar_Invite__c, 
                    Contact__c, 
                    Contact__r.Email, 
                    Event__r.Email_Sender_Id__c, 
                    Event__r.Email_Sender_Name__c, 
                    Event__r.Location__r.Name, 
                    Session__r.Do_Not_Send_Calendar_Invite__c, 
                    Session__r.Name, 
                    Session__r.Meeting_Info__c, 
                    Session__r.Start_Date_Time__c, 
                    Session__r.End_Date_Time__c, 
                    Session__r.Time_Zone__c, 
                    Session__r.Meeting_URL__c 
             FROM   Internal_Resource_Session__c 
             WHERE  Id IN :internalResourceIds AND 
                    Session__r.Do_Not_Send_Calendar_Invite__c = false AND 
                    Contact__r.Email != null AND 
                    Is_Eligible_For_Calendar_Invite__c = true]
        );

        if(resourceMap.isEmpty()) {
            return;
        }

        // *** EMAIL CREATION START ***

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // OrgWideEmail
        List < OrgWideEmailAddress > orgwide = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress];
        Map < String, OrgWideEmailAddress > orgwideMap = new Map < String, OrgWideEmailAddress > ();
        for (OrgWideEmailAddress o: orgwide) {
            orgwideMap.put(o.id, o);
        }

        String TimeZoneSidKey = [SELECT Id, TimeZoneSidKey FROM Organization].TimeZoneSidKey;

        // Get Custom Metadata for Time Zone offsets
        Map<String, Time_Zone_Offset__mdt> TZOffsets = Time_Zone_Offset__mdt.getAll();

        for(Internal_Resource_Session__c resource : resourceMap.values()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setOrgWideEmailAddressId(resource.Event__r.Email_Sender_Id__c);

            mail.setToAddresses(new List<String>{ resource.Contact__r.Email });

            mail.setSubject(resource.Session__r.Name);

            String htmlBody = (resource.Session__r.Meeting_Info__c != null ? resource.Session__r.Meeting_Info__c : '');

            mail.setHtmlBody(htmlBody);
            mail.setSaveAsActivity(true);
            mail.setTargetObjectId(resource.Contact__c);

            DateTime startDT    = resource.Session__r.Start_Date_Time__c;
            DateTime endDT      = resource.Session__r.End_Date_Time__c;
            DateTime modifiedDT = System.now();

            String startDTGMT       = startDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);
            String endDTGMT         = endDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);
            String modifiedDTGMT    = modifiedDT.format('MM/dd/yyyy/HH/mm/ss', TimeZoneSidKey);

            List<String> startDTtz      = startDTGMT.split('/');
            List<String> endDTtz        = endDTGMT.split('/');
            List<String> modifiedDTtz   = modifiedDTGMT.split('/');

            DateTime startDTNew = DateTime.newInstanceGMT(Integer.valueOf(startDTtz[2]), Integer.valueOf(startDTtz[0]), Integer.valueOf(startDTtz[1]), Integer.valueOf(startDTtz[3]),
                                  Integer.valueOf(startDTtz[4]), Integer.valueOf(startDTtz[5]));

            DateTime endDTNew = DateTime.newInstanceGMT(Integer.valueOf(endDTtz[2]), Integer.valueOf(endDTtz[0]), Integer.valueOf(endDTtz[1]), Integer.valueOf(endDTtz[3]),
                                Integer.valueOf(endDTtz[4]), Integer.valueOf(endDTtz[5]));
                                
            DateTime modifiedDTNew = DateTime.newInstanceGMT(Integer.valueOf(modifiedDTtz[2]), Integer.valueOf(modifiedDTtz[0]), Integer.valueOf(modifiedDTtz[1]), Integer.valueOf(modifiedDTtz[3]),
                                     Integer.valueOf(modifiedDTtz[4]), Integer.valueOf(modifiedDTtz[5]));

            // Apply offset from Custom Metadata
            Integer offset  = (Integer) (TZOffsets.get(resource.Session__r.Time_Zone__c).Offset__c * 60);
            startDT         = startDTNew.addMinutes(-offset);
            endDT           = endDTNew.addMinutes(-offset);
            modifiedDT      = modifiedDTNew.addMinutes(-offset);

            String startDTConverted     = startDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
            String endDTConverted       = endDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
            String modifiedDTConverted  = modifiedDT.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');

            //Create Meeting Body
            String meetingInviteBody = '';

            meetingInviteBody += 'BEGIN:VCALENDAR\n';
            meetingInviteBody += 'PRODID:-//Microsoft Corporation//Outlook 12.0 MIMEDIR//EN\n';
            meetingInviteBody += 'VERSION:2.0\n';

            meetingInviteBody += 'METHOD:REQUEST\n';

            meetingInviteBody += 'CALSCALE:GREGORIAN\n';
            meetingInviteBody += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
            meetingInviteBody += 'BEGIN:VEVENT\n';
            meetingInviteBody += 'CLASS:PUBLIC\n';
            meetingInviteBody += 'CREATED:' + modifiedDTConverted + '\n';
            meetingInviteBody += 'ORGANIZER;CN=' + resource.Event__r.Email_Sender_Name__c + ':MAILTO:' + orgwideMap.get(resource.Event__r.Email_Sender_Id__c).Address + '\n';
            meetingInviteBody += 'DTEND:' + endDTConverted + '\n';
            meetingInviteBody += 'DTSTAMP:' + modifiedDTConverted + '\n';
            meetingInviteBody += 'DTSTART:' + startDTConverted + '\n';
            meetingInviteBody += 'LAST-MODIFIED:' + modifiedDTConverted + '\n';
            meetingInviteBody += 'LOCATION:' + (resource.Session__r.Meeting_URL__c != null ? resource.Session__r.Meeting_URL__c : resource.Event__r.Location__r.Name) + '\n';
            meetingInviteBody += 'PRIORITY:5\n';
            meetingInviteBody += 'SEQUENCE:0\n';
            meetingInviteBody += 'SUMMARY:' + (resource.Session__r.Name != null ? resource.Session__r.Name : '') + '\n';
            meetingInviteBody += 'DESCRIPTION:' + (resource.Session__r.Meeting_Info__c != null ? resource.Session__r.Meeting_Info__c : '') + '\n';
            meetingInviteBody += 'LANGUAGE=en-us:Meeting\n';
            meetingInviteBody += 'TRANSP:OPAQUE\n';
            meetingInviteBody += 'UID:4036587160834EA4AE7848CBD028D1D200000000000000000000000000000000' + resource.Id + '\n';
            meetingInviteBody += 'X-ALT-DESC;FMTTYPE=text/html:<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000"><TITLE></TITLE></HEAD><BODY><!-- Converted from text/plain format -->' + resource.Session__r.Meeting_Info__c + '</BODY></HTML>\n';

            meetingInviteBody += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
            //CCN-EVE-3566-DV START RDAVID 11/29/2023
            meetingInviteBody += 'BEGIN:VALARM\n';
            meetingInviteBody += 'ACTION:DISPLAY\n';
            meetingInviteBody += 'DESCRIPTION:'+ (resource.Session__r.Name != null ? resource.Session__r.Name : '') + '\n';
            meetingInviteBody += 'TRIGGER:-PT15M\n';
            meetingInviteBody += 'END:VALARM\n';
            //CCN-EVE-3566-DV END RDAVID 11/29/2023
            meetingInviteBody += 'END:VEVENT\n';
            meetingInviteBody += 'END:VCALENDAR';

            // Meeting Email Attachment
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();

            attach.Filename     = 'meeting.ics';
            attach.ContentType  = 'text/calendar; charset=utf-8; method=REQUEST';
            attach.Inline       = true;
            attach.Body         = Blob.valueOf(meetingInviteBody);

            //Attach Meeting Attachment
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {
                attach
            });

            emailsToSend.add(mail);
        }
        // *** EMAIL CREATION END ***

        if(!emailsToSend.isEmpty()) {
            Boolean hasErrors = false;
            try{
                Messaging.SendEmailResult[] er = Messaging.sendEmail(emailsToSend);
            }
            catch(EmailException e) {
                hasErrors = true;
                System.debug('Error Sending Calendar Invites: ' + e.getMessage() + ' ' + e.getStackTraceString());
            }
            finally {
                if(!hasErrors) {
                    confirmCalendarInviteDelivery(resourceMap.keySet());
                }
            }            
        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  23-06-2022             Von Pernicia            [CCN-EVE-2390-DV] Intial Version. This will update date and time depends on the status value.
    ******************************************************************************/ 
    public static void updateDateTime(Internal_Resource_Session__c irsRecord) {

        if (irsRecord.Resource_Session_Status__c == 'Confirmed') {
            irsRecord.Resource_Confirmed_Date_Time__c = System.now();
        } else if (irsRecord.Resource_Session_Status__c == 'Declined') {
            irsRecord.Resource_Declined_Date_Time__c = System.now();
        } else if (irsRecord.Resource_Session_Status__c == 'Attended') {
            irsRecord.Resource_Attendance_Date_Time__c = System.now();
        } else if (irsRecord.Resource_Session_Status__c == 'Canceled') {
            irsRecord.Resource_Canceled_Date_Time__c = System.now();
        } 
    }

    @Future
    public static void confirmCalendarInviteDelivery(Set<Id> internalResourceSessionIds) {
        List<Internal_Resource_Session__c> resourceSessionsList = new List<Internal_Resource_Session__c>(
            [SELECT Calendar_Invite_Sent_to_Resource__c FROM Internal_Resource_Session__c WHERE Id IN : internalResourceSessionIds]
        );

        for(Internal_Resource_Session__c rs :  resourceSessionsList) {
            rs.Calendar_Invite_Sent_to_Resource__c = true;
        }

        update resourceSessionsList;
    }
}