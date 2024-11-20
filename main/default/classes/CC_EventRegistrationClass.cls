/**
@author Edison Crisostomo
@date 24 August 2020
@group NCC
@description Registration Page
@revision   Edison Crisostomo - 24 AUG 2020 - Initial version
Angelo Rivera - Added logic on linking Contact when user registers
Jasmine Nguyen - 10 SEPTEMBER 2020 - Modified code to use Start Date Time and End Date Time fields
Angelo Rivera - 31 OCT 2020 - Updated code to reference new custom objects.
Xen Reyes - 3 NOV 2021 - Updated code to look for dynamic fields in Registration Field Configuration Custom Metadata
JC Espino - 14 Feb 2022 - Added list empty check on sessionList in submitBooking method
Jayson Labnao - 12 Jun 2022 - Updated session end date filtering and updated Start Time and End Time String display values
**/
public with sharing class CC_EventRegistrationClass {

    private static WithoutSharingClass withoutShare = new WithoutSharingClass();
    private static final String SELECT_ONE = '-- Select One --';
    private static final String RESPONDED = 'Responded';
    private static final String INVITED = 'Invited';
    private static final String REGISTERED = 'Registered';

    @AuraEnabled
    public static resultWrapper DoInit(String campaignId, String pm) {

        resultWrapper returnResult = new resultWrapper();
        returnResult.SessionList = new List < SessionWrapper > ();
        List < Event__c > campaignRec = new List < Event__c > ();
        List < Participant__c > contactList = new List < Participant__c > ();
        List < Session__c > EventSessionList = new List < Session__c > ();

        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;

        //CCN-907 XEN REYES 11032021 - Adding the fields defined in the Event_Picklist_Field_API_Name__c from Registration Field Custom Metadata
        Map < String, Registration_Field_Configuration__mdt > regConfigMap = getEventFieldRegistrationMdt();
        Set < String > fieldsToAddSet = new Set < String > (); //to avoid duplicates
        String additionalFieldsToQuery = '';
        if (!regConfigMap.values().isEmpty()) {
            for (Registration_Field_Configuration__mdt regVar: regConfigMap.values()) {
                if (regVar.Event_Picklist_Field_API_Name__c != null) fieldsToAddSet.add(regVar.Event_Picklist_Field_API_Name__c);

                //XEN REYES CCN-SUR-3235-DV 14 July 2023
                if(regVar.Field_Type__c == 'Picklist' && regVar.Use_Picklist_Field_from_related_object__c && regVar.Related_Object_Field_API__c != null && regVar.Related_Object_Picklist_Field_API__c != null){
                    fieldsToAddSet.add(regVar.Related_Object_Field_API__c + '.' + regVar.Related_Object_Picklist_Field_API__c);
                }
            }

            //Construct the string to append to dynamic query
            if (!fieldsToAddSet.isEmpty()) {
                List < String > fieldsToAddList = new List < String > (fieldsToAddSet);
                additionalFieldsToQuery = ',';
                for (Integer i = 0; i <= fieldsToAddList.size() - 1; i++) {
                    if (i != fieldsToAddSet.size() - 1) {
                        additionalFieldsToQuery += fieldsToAddList[i] + ',';
                    } else {
                        additionalFieldsToQuery += fieldsToAddList[i] + ' ';
                    }
                }
            }
        }

        // campaignId = 'g3UZle8Tnj1';
        // Added for CRUD/FLS Enforcement
        if (FlsUtils.isAccessible('Event__c', new List < String > {
                'Name',
                'OwnerId',
                'Contact_Us_User__c',
                'Time_Zone__c',
                'Event_Id__c'
            })) {
            //CCN-907 XEN REYES 11032021 - added parameter for dynamic query
            campaignRec = withoutShare.getEvents(campaignId, additionalFieldsToQuery);
            
                /*-- CCN-EVE-2482-DV Gabriel Delavin Jan182023 !--*/
                if(!String.isBlank(campaignRec[0].Registration_Message__c)){
                    returnResult.RegistrationMessage = campaignRec[0].Registration_Message__c.stripHtmlTags();
                }
                returnResult.RegistrationTagline = campaignRec[0].Registration_Tag_Line__c; 
            }

        //CCN-907 XEN REYES 11032021 - Updated, added new parameter
        List < RegistrationFields > regFieldMappingList = getRegistrationFieldConfiguration(campaignRec.get(0).Registration_Fields_JSON__c, campaignRec.get(0).Id, campaignRec[0], regConfigMap);
        List < String > contactFieldsToQuery = new List < String > ();

        for (RegistrationFields regFieldRecord: regFieldMappingList) {
            if (String.isNotBlank(regFieldRecord.fieldName) &&
                regFieldRecord.objectName == 'Contact' &&
                !contactFieldsToQuery.contains(regFieldRecord.fieldName)) {
                contactFieldsToQuery.add(regFieldRecord.fieldName);
            }
        }

        if (FlsUtils.isAccessible('Event__c', new List < String > {
                'Name',
                'OwnerId',
                'Contact_Us_User__c',
                'Time_Zone__c',
                'Event_Id__c'
            })) {
            contactList = withoutShare.getParticipantsWithName(pm, contactFieldsToQuery);
        }

        if (!campaignRec.isEmpty()) {
            //Added CCN-1732 JaysonLabnao June102022
            Map < String, SFTimezone__mdt > timezoneMap = SFTimezone__mdt.getAll();

            //TO-DO remove the campaign Id once the site field is finalized
            //returnResult.registrationFieldList = getRegistrationFieldConfiguration(campaignRec.get(0).Registration_Fields_JSON__c, campaignRec.get(0).Id);

            // Added for CRUD/FLS Enforcement
            if (FlsUtils.isAccessible('Session__c', new List < String > {
                    'Name',
                    'Start_Date_Time__c',
                    'End_Date_Time__c',
                    'Time_Zone__c',
                    'IsActive__c'
                })) {

                EventSessionList = withoutShare.getEventSessions(campaignRec[0].Id);
            }
            if (contactList.size() > 0) {
                returnResult.participantRecordList = contactList;
            }
            returnResult.registrationFieldList = regFieldMappingList;
            if (EventSessionList.size() > 0) {
                //Modified CCN-1732 JaysonLabnao June102022
                Datetime dateNow = System.now();
                for (Session__c session: EventSessionList) {
                    SessionWrapper sessionwrapper = new SessionWrapper();
                    
                    String timezoneLocation = (String) timezoneMap.get(session.Time_Zone__c).get('Timezone_Name__c');
                    sessionwrapper.isSelected = false;
                    sessionwrapper.EventId = session.Id;
                    sessionwrapper.EventName = session.Name;
                   
                    Datetime startDateTime;
                    Datetime endDateTime;
                    Datetime computedStartDate;
                    Datetime computedEndDate;
                    if (timezoneMap.containsKey(session.Time_Zone__c)) {
                        // remove comma in End_Date_Time2__c field
                        startDateTime = DateTime.parse(session.Start_Date_Time2__c.Replace(',', ''));
                        computedStartDate = computeTimeZoneDiff(startDateTime, timezoneLocation);
                        endDateTime = DateTime.parse(session.End_Date_Time2__c.Replace(',', ''));
                        computedEndDate = computeTimeZoneDiff(endDateTime, timezoneLocation);
                    }

                    sessionwrapper.EventDate = computedStartDate.format('MMMM d, yyyy', timezoneLocation);
                    sessionwrapper.StartTime = computedStartDate.format('h:mm a', timezoneLocation) + ' ' + session.Time_Zone__c;
                    sessionwrapper.EndTime = computedEndDate.format('h:mm a', timezoneLocation) + ' ' + session.Time_Zone__c;
                    if (computedEndDate != null && dateNow < computedEndDate) {
                        returnResult.SessionList.add(sessionwrapper);
                    }
                }
            }

            return returnResult;
        } else {
            return null;
        }
    }

    /******************************************************************************    
     * Changes (version)
     *            No.  Date(dd-mm-yyyy) Author                Description
     *           ----  ---------        --------------------  ----------------------
     * @version   1.0  10-06-2022       Jayson Labnao         [CCN-1732] Initial version.
     ******************************************************************************/
    public static DateTime computeTimeZoneDiff(DateTime inputDT, String timezoneLocation) {
        Datetime inDateTime = Datetime.newInstanceGmt(
            inputDT.year(),
            inputDT.month(),
            inputDT.day(),
            inputDT.hour(),
            inputDT.minute(),
            inputDT.second()
        );
        string dateTimeStr = inDateTime.format('yyyy-MM-dd HH:mm:ss', timezoneLocation);
        string dateGmtStr = inDateTime.formatGMT('yyyy-MM-dd HH:mm:ss');
        Datetime localDateTime = DateTime.valueOf(dateTimeStr);
        Datetime baseGMTTime = DateTime.valueOf(dateGMTStr);
        Long milliSecDiff = baseGMTTime.getTime() - localDateTime.getTime();
        Long minDiff = milliSecDiff / 1000 / 60;
        Datetime outDateTime = inDateTime.addMinutes(minDiff.intValue());
        return outDateTime;
    }

    public static String getCampaignMemberStatus(Id contactId, Id campaignId) {
        List < Participant__c > cmpMemberList = new List < Participant__c > ();
        if (FlsUtils.isAccessible('Participant__c', new List < String > {
                'Name',
                'Status__c',
                'Event__c',
                'Member_Contact__c'
            })) {
            cmpMemberList = withoutShare.getParticipants(campaignId, contactId);
        }

        return !cmpMemberList.isEmpty() ? cmpMemberList.get(0).Status__c : 'Not Registered';
    }

    private static Map < String, SObject > parseFormAnswers(String formDetailAnswers) {
        Map < String, SObject > objectMap = new Map < String, SObject > ();

        if (String.isNotBlank(formDetailAnswers)) {
            Map < String, String > formResultMap = (Map < String, String > ) JSON.deserialize(formDetailAnswers, Map < String, String > .class);

            for (String keyFieldStr: formResultMap.keySet()) {
                List < String > developerName = keyFieldStr.unescapeHtml4().split('\\-');
                String objName = developerName[1].unescapeHtml4().split('\\|')[0];
                String fieldName = developerName[1].unescapeHtml4().split('\\|')[1];
                String prefixedObjName = objName.endsWith('__c') ? FLSUtils.prefix + objName : objName;
                String prefixedFieldName = fieldName.endsWith('__c') ? FLSUtils.prefix + fieldName : fieldName;

                if (!objectMap.containsKey(objName)) {
                    objectMap.put(objName, Schema.getGlobalDescribe().get(prefixedObjName).newSObject());
                }

                objectMap.get(objName).put(prefixedFieldName, formResultMap.get(keyFieldStr));
            }
        }

        return objectMap;
    }

    /******************************************************************************    
     * Changes (version)
     *            No.  Date(dd-mm-yyyy) Author                Description
     *           ----  ---------        --------------------  ----------------------
     * @version   1.0  ???               ???                  ???
     * @version   1.1  14-06-2022       Jayson Labnao         [CCN-1732] Removed system.debug as per Technical Review.
     ******************************************************************************/
    @AuraEnabled
    public static String submitBooking(String campaignId, String fieldInputs, List < String > sessionIds, String currentRankValue) {
        Boolean insertParticipant = true;
        Boolean insertSession = true;
        List < Event__c > campaignRec = new List < Event__c > ();
        List < Contact > lstContacts = new List < Contact > ();
        Id eventId = null;

        if (FlsUtils.isAccessible('Event__c', new List < String > {
                'Name'
            })) {
            //CCN-907 XEN REYES 11032021
            campaignRec = withoutShare.getEvents(campaignId, '');
        }

        Map < String, SObject > formAnswers = parseFormAnswers(fieldInputs);
        Contact contactRecord = formAnswers.containsKey('Contact') ? (Contact) formAnswers.get('Contact') : new Contact();

        //CCN-907 XEN REYES 11032021
        Contact conTemp = contactRecord;

        if (FlsUtils.isAccessible('Contact', new List < String > {
                'Email'
            }) && String.isNotBlank(contactRecord.Email)) {
            lstContacts = withoutShare.getContacts(contactRecord.Email);
        }

        Contact contactRec = new Contact();
        eventId = campaignRec.get(0).Id;
        Participant__c participant = new Participant__c();
        participant.Event__c = campaignRec.get(0).Id;
        participant.Process_from_Event_Page__c = true;
        Participant__c cmp = new Participant__c();

        if (!lstContacts.isEmpty()) { //Search for existing contact
            contactRec = lstContacts.get(0);
            String strStatus = getCampaignMemberStatus(contactRec.Id, campaignRec.get(0).Id);

            if (strStatus == INVITED) { // If Status is Sent, update to Responded

                if (FlsUtils.isAccessible('Participant__c', new List < String > {
                        'Status__c',
                        'Member_Contact__c'
                    })) {
                    cmp = withoutShare.getParticipantsWithContact(campaignRec.get(0).Id, contactRec.Id);
                }
                
                /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
                //cmp.Status__c = 'In Progress'; //RESPONDED;
                
                cmp.Process_from_Event_Page__c = true;
                if (FlsUtils.isAccessible('Participant__c', new List < String > {
                        'Status__c'
                    })) {
                    withoutShare.updateParticipant(cmp);
                }

                insertParticipant = false;
                participant.Id = cmp.Id;
            } else { //Add the contact as campaign member
                participant.Member_Contact__c = contactRec.Id;

                /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
                //participant.Status__c = 'In Progress'; //RESPONDED; 
            }

            //CCN-907 XEN REYES 11032021, CCN-EVE-2434-DV XEN REYES Jan 17 2023
            /* if (formAnswers.containsKey('Contact') &&
                FlsUtils.isCreateable(
                    contactRec,
                    new List < String > {
                        'Department',
                        'Site__c',
                        'Title'
                    }
                )

            ) { */
            
            //CCN-EVE-2434-DV XEN REYES Jan 17 2023
            Boolean updateContact = false;
            Contact conUpdate = new Contact(Id = contactRec.Id);

            if (conTemp.Department != null) {
                conUpdate.Department = conTemp.Department;
                updateContact = true;
            }

            if (conTemp.Site__c != null) {
                conUpdate.Site__c = conTemp.Site__c;
                updateContact = true;
            }
			
            if (conTemp.Title != null) {

                if(conTemp.Title.contains('|')){
                    List<String> rankPair = conTemp.Title.split('\\|');
                    conUpdate.Title = rankPair[0];
                } else {
                    conUpdate.Title = conTemp.Title;
                }

                updateContact = true;
            }

            if(updateContact) withoutShare.updateContact(conUpdate);

        } else { //checks for existing lead to be converted to contact as participant
            List < Lead > lstLeads = new List < Lead > ();
            if (FlsUtils.isAccessible('Lead', new List < String > {
                    'Name',
                    'Email'
                })) {
                lstLeads = withoutShare.getLeads(contactRecord.Email);
            }
            if (!lstLeads.isEmpty()) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lstLeads.get(0).Id);
                lc.setDoNotCreateOpportunity(true);
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                contactRec.Id = lcr.getContactId();
            } else {
                //use dynamic contact fields from form if there is any contact fields configured
                Contact conRecord = contactRecord;

                if (formAnswers.containsKey('Contact') && FlsUtils.isCreateable(conRecord, new List < String > {
                        'FirstName',
                        'LastName',
                        'Email'
                    })) {
                    withoutShare.createContact(conRecord);
                }

                contactRec.Id = conRecord.Id;
            }

            participant.Member_Contact__c = contactRec.Id;

            /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
            //participant.Status__c = 'In Progress'; //RESPONDED;
        }

        List < Participant__c > existingParticipantList = new List < Participant__c > ();
        if (contactRec.Id != null && eventId != null) {
            if (FlsUtils.isAccessible('Participant__c', new List < String > {
                    'Id',
                    'Event__c',
                    'Process_from_Event_Page__c',
                    'Member_Contact__c',
                    'Status__c'
                })) {
                existingParticipantList = withoutShare.checkExistingParticipants(contactRec.Id, eventId);
            }
        }
        if (!existingParticipantList.isEmpty()) {
            participant = existingParticipantList[0];
        } else {
            if (FlsUtils.isCreateable(participant, new List < String > {
                    'Member_Contact__c',
                    'Status__c',
                    'Event__c'
                })) {
                if (insertParticipant) {
                    withoutShare.createParticipant(participant);
                }
            }
        }

        if (insertSession) {
            //Inserts Sessions against the participant
            List < Session_Participant__c > sessionList = new List < Session_Participant__c > ();
            List < Session_Participant__c > existingParticipants = withoutShare.getExistingSessionParticipant(sessionIds, contactRec.Id);
            Map < Id, Boolean > existCheck = new Map < Id, Boolean > ();

            for (String sessionId: sessionIds) {
                for (Session_Participant__c existingParticipant: existingParticipants) {
                    if (existingParticipant.Session__c == sessionId) {
                        existCheck.put(sessionId, TRUE);
                    }
                }

                if (!existCheck.containsKey(sessionId)) {
                    Session_Participant__c sessionRec = new Session_Participant__c();
                    sessionRec.Participant__c = participant.Id;
                    sessionRec.Event__c = campaignRec.get(0).Id;
                    sessionRec.Session__c = sessionId;
                    sessionRec.Contact__c = contactRec.Id;

                    System.debug('currentRankValue: ' + currentRankValue);

                    if(currentRankValue != null && currentRankValue.contains('|')){
                        List<String> rankPair = currentRankValue.split('\\|');
                        sessionRec.Rank__c = rankPair[0];
                        sessionRec.Branch_of_Service__c = rankPair[1] == null ? 'Other' : rankPair[1];
                    } else {
                        sessionRec.Rank__c = currentRankValue;
                        sessionRec.Branch_of_Service__c = 'Other';
                    }
                    
                    sessionList.add(sessionRec);
                }
            }
            try {

                // Updated by JC ESPINO [CCN-1149] FEB142022
                // Added list empty check
                if (!sessionList.isEmpty() &&
                    FlsUtils.isCreateable(sessionList[0], new List < String > {
                        'Participant__c',
                        'Event__c',
                        'Session__c',
                        'Contact__c'
                    })) {
                    withoutShare.createSessionParticipant(sessionList);
                }

                participant.Session_Modified__c = true;

                if (FlsUtils.isUpdateable(participant, new List < String > {
                        'Session_Modified__c',
                        'Member_Contact__c',
                        'Status__c',
                        'Event__c'
                    })) {
                    withoutShare.updateParticipant(participant);
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.DEBUG, '--- Insert Error: ' + ex.getMessage());
            }
        }

        return 'Success';
    }

    public static List < RegistrationFields > getRegistrationFieldConfiguration(String eventRegistrationJSON, String eventId, Event__c eventRec, Map < String, Registration_Field_Configuration__mdt > regConfigMap) {
        List < RegistrationFields > regFieldList = new List < RegistrationFields > ();

        //CCN-907 XEN REYES 11032021 - Updated. Moved in outer class to query other fields together with the event record.
        //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
        //                                            - Update JSON Deserialize data type. From Map<String, Boolean> to Map<String, Map <String,Boolean>>
        Map<String, Map <String,Boolean>> regFieldConfig = new Map<String, Map <String,Boolean>>();
        //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
        try {
            if (String.isNotBlank(eventRegistrationJSON)) {
                //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                //                                            - Update JSON Deserialize data type. From Map<String, Boolean> to Map<String, Map <String,Boolean>>
                regFieldConfig = (Map<String, Map <String,Boolean>>) JSON.deserialize(eventRegistrationJSON, Map<String, Map <String,Boolean>>.class);
                //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
            }
            for (String key: regConfigMap.keySet()) {
                Registration_Field_Configuration__mdt regField = regConfigMap.get(key);
				system.debug(key);
                RegistrationFields field = new RegistrationFields(key, regField.Label,
                    regFieldConfig.containsKey(key) && regFieldConfig.get(key).containsKey('required') ? regFieldConfig.get(key).get('required') : regField.Is_Required__c,
                    //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                    //                                            - Add active parameter
                    regFieldConfig.containsKey(key) && regFieldConfig.get(key).containsKey('active') ? regFieldConfig.get(key).get('active') : true,
                    //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                    regField.Object_API_Name__c, regField.Field_API_Name__c, regField.Field_Type__c,
                    regField.Message_when_Required__c);

                final Boolean SHOULD_ADD_TO_LIST = regFieldConfig.isEmpty() || (!regFieldConfig.isEmpty() && regFieldConfig.containsKey(key));
                
				
                if (regField.Field_Type__c == 'Picklist') {

                    if (regField.Actual_Field_Type__c == 'Text') {

                        if (regField.Has_null_picklist_value__c) field.picklistOptions.add(new RegistrationFields.PicklistOptions('', '-----')); //CCN-EVE-1881-DV XEN REYES 18072022

                        //CCN-907 XEN REYES 11032021
                        if (regField.Use_event_field__c && eventRec != null && eventRec.get(regField.Event_Picklist_Field_API_Name__c) != null) {
                            field.picklistOptions.addAll(setPicklist(String.valueOf(eventRec.get(regField.Event_Picklist_Field_API_Name__c))));
                            field.inputValue = field.picklistOptions[0].value;
                            
                        //XEN REYES CCN-SUR-3235-DV 14 July 2023
                        } else if (regField.Use_Picklist_Field_from_related_object__c && regField.Related_Object_Field_API__c != null && regField.Related_Object_Picklist_Field_API__c != null) {
                            Sobject eventCont = (Sobject) eventRec;
                            String plValues = (String) eventCont.getSobject(regField.Related_Object_Field_API__c).get(regField.Related_Object_Picklist_Field_API__c);
                            if(plValues != null) field.picklistOptions = setPicklist(plValues);
                        
                        } else if (String.isNotBlank(regField.Picklist_Options__c)) {
                            field.picklistOptions.addAll(setPicklist(regField.Picklist_Options__c));
                            // default the value to the first option
                            field.inputValue = field.picklistOptions[0].value;
                        }
                    }

                    if (!field.picklistOptions.isEmpty() && SHOULD_ADD_TO_LIST) {
                        regFieldList.add(field);
                    }

                } else if (SHOULD_ADD_TO_LIST) {
                    regFieldList.add(field);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return regFieldList;
    }

    private static List < RegistrationFields.PicklistOptions > setPicklist(String picklistOptionsStr) {
        List < RegistrationFields.PicklistOptions > stringList = new List < RegistrationFields.PicklistOptions > ();

        List < String > picklistSplittedVal = picklistOptionsStr.split(',');
        for (String value: picklistSplittedVal) {
            String val = value.trim();
            stringList.add(new RegistrationFields.PicklistOptions(val, val));
        }

        return stringList;
    }

    private static Map < String, Registration_Field_Configuration__mdt > getEventFieldRegistrationMdt() {
        Map < String, Registration_Field_Configuration__mdt > regFieldConfig = new Map < String, Registration_Field_Configuration__mdt > ();
        for (Registration_Field_Configuration__mdt config: [SELECT Label, Order__c, Field_API_Name__c, Field_Type__c, Is_Required__c, Picklist_Options__c,
                Object_API_Name__c, DeveloperName, Message_when_Required__c, Actual_Field_Type__c,
                Use_event_field__c, Event_Picklist_Field_API_Name__c, //CCN-907 XEN REYES 11032021
                Has_null_picklist_value__c, //CCN-EVE-1881-DV XEN REYES 18072022
                Use_Picklist_Field_from_related_object__c, Related_Object_Field_API__c, Related_Object_Picklist_Field_API__c //XEN REYES CCN-SUR-3235-DV 14 July 2023
                FROM Registration_Field_Configuration__mdt
                WHERE Is_Active__c = true
                ORDER BY Order__c
                LIMIT 5000
            ]) {
                
                //Updated [CCN3301] title override; Since the future plan is to map the TitleRank to the title field in Contact
                regFieldConfig.put(config.DeveloperName + '-' + config.Object_API_Name__c + '|' + config.Field_API_Name__c, config);
            
        }

        return regFieldConfig;
    }
    
    //Fetch Rank Values [CCN3301] title override
    @AuraEnabled
    public static Map<Object,List<String>> getRankAndRankGroupDependencies() {
        Schema.DescribeFieldResult F = Session_Participant__c.Rank__c.getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        return ChangeCloudController.getDependentPicklistValues(T);
    }

    public class resultWrapper {
        /*@AuraEnabled public String FirstName {get;set;}
        @AuraEnabled public String LastName {get;set;}
        @AuraEnabled public String Email {get;set;}
        @AuraEnabled public String Department {get;set;}*/
        @AuraEnabled public Map < String, String > DefaultFieldValueMapping {
            get;
            set;
        }
        @AuraEnabled public List < SessionWrapper > SessionList {
            get;
            set;
        }
        @AuraEnabled public List < RegistrationFields > registrationFieldList {
            get;
            set;
        }
        @AuraEnabled public List < Participant__c > participantRecordList {
            get;
            set;
        }
        /*-- CCN-EVE-2482-DV Gabriel Delavin Jan182023 !--*/
    	@AuraEnabled public String RegistrationMessage {
            get;
            set;
        }
        @AuraEnabled public String RegistrationTagline {
            get;
            set;
        }
    }

    public class SessionWrapper {
        @AuraEnabled public boolean isSelected {
            get;
            set;
        }
        @AuraEnabled public String EventId {
            get;
            set;
        }
        @AuraEnabled public String EventName {
            get;
            set;
        }
        @AuraEnabled public String EventDate {
            get;
            set;
        }
        @AuraEnabled public String StartTime {
            get;
            set;
        }
        @AuraEnabled public String EndTime {
            get;
            set;
        }
        @AuraEnabled public String TimezoneLocation {
            get;
            set;
        } //Added CCN-1732 JaysonLabnao June102022
         
    }

    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {

        public void createSessionParticipant(List < Session_Participant__c > sessionList) {
            insert sessionList;
        }

        public void createParticipant(Participant__c cmp) {
            insert cmp;
        }
        public List < Participant__c > checkExistingParticipants(Id contactId, Id eventId) {
            return [SELECT Id, Event__c, Process_from_Event_Page__c, Member_Contact__c, Status__c FROM Participant__c WHERE Event__c =: eventId AND Member_Contact__c =: contactId LIMIT 1];
        }

        public void createContact(Contact conRecord) {
            insert conRecord;
        }

        //CCN-907 XEN REYES 11032021
        public void updateContact(Contact conRecord) {
            update conRecord;
        }

        public void updateParticipant(Participant__c cmp) {
            update cmp;
        }

        public List < Contact > getContacts(String email) {
            return [SELECT Id, Email FROM Contact WHERE Email =: email ORDER BY LastModifiedDate DESC];
        }

        public List < Lead > getLeads(String email) {
            return [SELECT Id, Name, Email FROM Lead WHERE Email =: email ORDER BY LastModifiedDate DESC];
        }

        /******************************************************************************    
         * Changes (version)
         *            No.  Date(dd-mm-yyy) Author            Description
         *           ----  ---------   --------------------  -----------------------------
         * @version   1.0  ??           ??                   Initial version.
         * @version   2.0  ??          JC Espino            [CCN-EVE-1515-DV] - added filter to get Sessions not ended yet
         *            3.0  ??          JC Espino            [CCN-EVE-1656-DV] - added filter to not include full sessions
         *            3.1  ??          Jayson labnao            [CCN-1732] - removed end date filter
         ******************************************************************************/
        public List < Session__c > getEventSessions(String campaignId) {
            return [SELECT Id, Name, Event__r.Registration_Tag_Line__c, Start_Date_Time__c, Start_Date_Time2__c, End_Date_Time__c, End_Date_Time2__c, Time_Zone__c, Session_Details_Full__c, Session_Full__c
                FROM Session__c
                WHERE Event__c =: campaignId AND
                IsActive__c = true AND
                Session_Full__c = false
                ORDER BY Start_Date_Time__c, Name
            ];
        }

        public List < Event__c > getEvents(String campaignId, String additionalFieldsToQuery) {
            //CCN-907 XEN REYES 11032021 - Updated query
            //Replace with unbounded query - FIELDS(Custom) once become supported, for now dynamic query will suffice
            //https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_fields.htm#bounded_and_unbounded_queries
            String strQuery = 'SELECT Id, Name, Registration_Tag_Line__c, Registration_Message__c, Registration_Fields_JSON__c ' + additionalFieldsToQuery + 'FROM Event__c WHERE Event_Id__c =: campaignId';
            return Database.query(strQuery);
        }

        public List < Participant__c > getParticipants(String campaignId, String contactId) {
            return [SELECT Id, Name, Status__c FROM Participant__c WHERE Event__c =: campaignId AND Member_Contact__c =: contactId];
        }

        public Participant__c getParticipantsWithContact(String campaignId, String contactId) {
            return [SELECT Id, Status__c, Member_Contact__c, Process_from_Event_Page__c
                FROM Participant__c
                WHERE Event__c =: campaignId AND Member_Contact__c =: contactId
            ];
        }

        public List < Session_Participant__c > getExistingSessionParticipant(List < String > sessionIds, String contactId) {
            return [SELECT Id, Session__c FROM Session_Participant__c WHERE Session__c IN: sessionIds AND Contact__c =: contactId];
        }

        public List < Participant__c > getParticipantsWithName(String pm, List < String > fieldsToQuery) {
            String queryStart = 'SELECT Id, ';
            String queryEnd = ' FROM Participant__c WHERE Name =: pm LIMIT 1';
            for (Integer i = 0; i < fieldsToQuery.size(); i++) {
                String comma = ',';
                queryStart = i != fieldsToQuery.size() - 1 ? queryStart + ' Member_Contact__r.' + fieldsToQuery[i] + comma : queryStart + ' Member_Contact__r.' + fieldsToQuery[i];

            }
            return Database.query(queryStart + queryEnd);
        }

    }

}