public class StatusReportUtilityClass {
    
    public static void UpdateEmailBody(list<Status_Report__c> triggerNew){
        
        set<Id> eventIdSet = new set<Id>();
        
        for(Status_Report__c strReport : triggerNew){
            if(strReport.Event__c!=null){
                eventIdSet.add(strReport.Event__c); 
            }
        }
        
        Map<Id,Event__c> evtMap = new Map<Id,Event__c>([select id,Name from event__c where Id IN :eventIdSet]);
        
        for(Status_Report__c strReport : triggerNew){
            strReport.Email_Body__c = '';
            
            if(strReport.Status__c == 'For PM Approval'){
                strReport.Email_Body__c =  '<html>Hello Technical Editing Approvers,';
                strReport.Email_Body__c += '<br><br>You have been identified as the Tech Editing Approver for the ';
            }
            
            else if(strReport.Status__c == 'For Final QA'){
                strReport.Email_Body__c =  '<html>Hello Quality Assurance Approvers,';
                strReport.Email_Body__c += '<br><br>You have been identified as the QA Approver for the ';
            }
            
            else {
                strReport.Email_Body__c =  '<html>Hello Project Team Approvers,';
                strReport.Email_Body__c += '<br><br>You have been identified as the Project Team Approver for the ';
            }
            
            strReport.Email_Body__c += strReport.Name + ' of the ' + evtMap.get(strReport.Event__c).Name + ' event from ' + strReport.Report_Date__c.format() + '.<br><br>'; 
            
            String strDate='';
            
            if(strReport.Due_Date__c!=null){
                strDate = strReport.Due_Date__c.format();
            }else{
                strDate = '';
            }
            
            if(strReport.timezone1__c!=null){
                strReport.Email_Body__c += 'Your Tasks: <br> Please review the status report linked below. Approve or reject this status report by clicking <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + strReport.Id + '">HERE</a>. Please note this report is due to the client by '+ strDate +' ' + strReport.timezone1__c + '. If you approve this item, will be sent to Tech Editing for approval. If you reject this item, it will go back to the record creator to update the status report based on your feedback.';
            }else{
                strReport.Email_Body__c += 'Your Tasks: <br> Please review the status report linked below. Approve or reject this status report by clicking <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + strReport.Id + '">HERE</a>. Please note this report is due to the client by '+ strDate +' ' + '. If you approve this item, will be sent to Tech Editing for approval. If you reject this item, it will go back to the record creator to update the status report based on your feedback.';
            }
            strReport.Email_Body__c += '<br><br>Status Report Link: <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + strReport.Id + '">' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + strReport.Id + '</a></html>';
        }
    }
    
    public static void updateParkingLotsAndSurveys(list<Status_Report__c> triggerNew){        
        set<String> roleName = new set<String>{'Super User Facilitator','Walk-in','Observer','Walk-In'};
            Map<Id,id> mapEvtIdReportId = new Map<Id,id>();
        Map<Id,list<Parking_Lot__c>> mapEvtIdParkingLot = new Map<Id,list<Parking_Lot__c>>();
        Map<Id,Id> mapsessionRptLocation = new Map<Id,Id>();
        DateTime statusreportdate;
        DateTime statusreportdate1;
        
        for(Status_Report__c strReport : triggerNew){
            strReport.Session_Attendance_2__c = '';
            strReport.Parking_Lots__c = '';
            statusreportdate =  strReport.Report_Date__c;
            statusreportdate1 = statusreportdate.addMinutes(1439);
            if(strReport.Event__c!=null){
                mapEvtIdReportId.put(strReport.Event__c,strReport.id); 
                mapsessionRptLocation.put(strReport.Id,strReport.Session_Location__c);
                system.debug('mapEvtIdReportId'+mapEvtIdReportId);
            }
        }
        
        if(mapEvtIdReportId.size()>0){
            list<Parking_Lot__c> listOfParking = [SELECT id,Event__c,Description__c,Resolution_Answer__c,Show_In_Status_Report__c 
                                                  FROM Parking_Lot__c 
                                                  WHERE Event__c IN :mapEvtIdReportId.keySet() and Show_In_Status_Report__c=true and createdDate>=:statusreportdate and createdDate<=:statusreportdate1];
            system.debug('listOfParking'+listOfParking);
            if(listOfParking.size()>0){
                for(Parking_Lot__c objPark : listOfParking){
                    if(!mapEvtIdParkingLot.containskey(objPark.Event__c)){
                        mapEvtIdParkingLot.put(objPark.Event__c,new list<Parking_Lot__c>());
                    }if(mapEvtIdParkingLot.get(objPark.Event__c).size()<3){
                        mapEvtIdParkingLot.get(objPark.Event__c).add(objPark);
                        system.debug('objPark'+objPark);
                    }
                }
                
                if(mapEvtIdParkingLot.size()>0){
                    for(Status_Report__c objStatus : triggerNew){
                        if(objStatus.Event__c!=null && mapEvtIdParkingLot.containskey(objStatus.Event__c)){
                            objStatus.Parking_Lots__c = '';
                            for(Parking_Lot__c objPark : mapEvtIdParkingLot.get(objStatus.Event__c)){
                                if(objPark.Resolution_Answer__c!=null){
                                    objStatus.Parking_Lots__c += '<b>Q.</b>' + ' ' + objPark.Description__c + '<br>' + '<b>A.</b>' +' '+ objPark.Resolution_Answer__c + '<br><br>';     
                                }else{
                                    objStatus.Parking_Lots__c += '<b>Q.</b>' + ' ' + objPark.Description__c + '<br>' + '<b>A.</b>' +' This item has been escalated.' + '<br><br>';     
                                }
                                
                            }
                            objStatus.Parking_Lots__c += '';
                        }
                    }
                } 
            }
        }
        Map<Id,list<Id>> mapSessionId = new Map<Id,list<Id>>();
        Map<Id,list<Session_Participant__c>> mapSessionIdParticipant = new Map<Id,list<Session_Participant__c>>();
        Map<Id,list<Session_Role__c>> mapSessionIdRole = new Map<Id,list<Session_Role__c>>();
        Map<id,Session__c> mapSessionDetail= new Map<id,Session__c>();
        Map<Id,Set<String>> statusReportIdSessionLocationName = new Map<Id,Set<String>>();
        Map<Id,Set<Id>> statusReportIdSessionLocation = new Map<Id,Set<Id>>();
        
       list<Session__c> listOfSession;
        if(mapEvtIdReportId.size()>0){
            if(triggerNew[0].Session_Location__c!=null){
                listOfSession = [SELECT id,Event__c,Session_Location__r.Name,Session_Location__c,Start_Date_Time__c,Name 
                                 FROM Session__c 
                                 WHERE Event__c IN :mapEvtIdReportId.keySet() AND IsActive__c=true and Start_Date_Time__c>:statusreportdate AND Start_Date_Time__c<:statusreportdate1 AND Session_Location__c=:triggerNew[0].Session_Location__c order by Start_Date_Time__c desc];
            }else{
                listOfSession = [SELECT id,Event__c,Session_Location__r.Name,Session_Location__c,Start_Date_Time__c,Name 
                                 FROM Session__c 
                                 WHERE Event__c IN :mapEvtIdReportId.keySet() AND IsActive__c=true and Start_Date_Time__c>:statusreportdate AND Start_Date_Time__c<:statusreportdate1 AND Session_Location__c=null order by Start_Date_Time__c desc];
            }
            
            system.debug('listOfSession'+listOfSession);
            if(listOfSession.size()>0){
                /*Datetime dt = listOfSession[0].Start_Date_Time__c;
Date sessionDate = date.newinstance(dT.year(), dT.month(), dT.day());
system.debug('sessionDate'+sessionDate);
Datetime sessionDate1 = sessionDate;
sessionDate1 = sessionDate1.addMinutes(1439);
system.debug('sessionDate1'+sessionDate1);
system.debug('statusreportdate'+statusreportdate);
system.debug('statusreportdate1'+statusreportdate1);
listOfSession = [SELECT id,Event__c,Start_Date_Time__c,Name 
FROM Session__c 
WHERE Event__c IN :mapEvtIdReportId.keySet() AND IsActive__c=true AND Start_Date_Time__c>=:statusreportdate AND Start_Date_Time__c<=:statusreportdate1  and Start_Date_Time__c>=:sessionDate and Start_Date_Time__c<=:sessionDate1 AND Session_Location_lookup__c=:triggerNew[0].Session_Location__c order by Start_Date_Time__c];
*/
                for(Session__c ObjSession : listOfSession){
                    
                    if(!statusReportIdSessionLocation.containsKey(mapEvtIdReportId.get(ObjSession.Event__c))){
                        statusReportIdSessionLocationName.put(mapEvtIdReportId.get(ObjSession.Event__c),new Set<String>());
                        statusReportIdSessionLocation.put(mapEvtIdReportId.get(ObjSession.Event__c),new Set<Id>());
                    }
                    statusReportIdSessionLocationName.get(mapEvtIdReportId.get(ObjSession.Event__c)).add(ObjSession.Session_Location__r.Name);
                    statusReportIdSessionLocation.get(mapEvtIdReportId.get(ObjSession.Event__c)).add(ObjSession.Session_Location__c);
                    
                    
                    mapSessionDetail.put(ObjSession.id, ObjSession);
                    if(!mapSessionId.containsKey(ObjSession.Event__c)){
                        mapSessionId.put(ObjSession.Event__c, new list<Id>());
                    }
                    mapSessionId.get(ObjSession.Event__c).add(ObjSession.Id);
                }
                
                if(mapSessionDetail.size()>0){
                    list<Session_Participant__c> listParticipant = [Select id,Session__c,Status__c from Session_Participant__c where Session__c IN :mapSessionDetail.keySet() AND (Status__c='Registered' OR Status__c='Attended')];
                    list<Session_Role__c> roleList = [Select Session__c,Role_Title__c,Number_of_Role__c from Session_Role__c where Session__c IN :mapSessionDetail.keySet()];
                    if(listParticipant.size()>0){
                        for(Session_Participant__c objParticipant : listParticipant){
                            if(!mapSessionIdParticipant.containsKey(objParticipant.Session__c)){
                                mapSessionIdParticipant.put(objParticipant.Session__c,new list<Session_Participant__c>());
                            }
                            mapSessionIdParticipant.get(objParticipant.Session__c).add(objParticipant);
                        }
                    }
                    
                    if(roleList.size()>0){
                        for(Session_Role__c objrole : roleList){
                            if(!mapSessionIdRole.containsKey(objrole.Session__c)){
                                mapSessionIdRole.put(objrole.Session__c,new list<Session_Role__c>());
                            }
                            mapSessionIdRole.get(objrole.Session__c).add(objrole);
                        }
                    }
                    
                    for(Status_Report__c objStatus : triggerNew){
                        if(objStatus.Event__c!=null && mapSessionId.containskey(objStatus.Event__c)){
                            objStatus.Session_Attendance_2__c = '<ul>';
                            for(Id sessionId : mapSessionId.get(objStatus.Event__c)){
                                Integer AttendedCount=0;
                                if(mapSessionIdParticipant.containskey(sessionId)){
                                    for(Session_Participant__c objParticipant : mapSessionIdParticipant.get(sessionId)){
                                        if(objParticipant.Status__c == 'Attended'){
                                            AttendedCount++;   
                                        }
                                    }
                                }                                
                                if(mapSessionIdParticipant.containskey(sessionId)){
                                    objStatus.Session_Attendance_2__c += '<li>' + mapSessionDetail.get(sessionId).Name + '<b> &mdash; ' + AttendedCount + ' attended of ' + mapSessionIdParticipant.get(sessionId).size() + ' registered</b>'; 
                                }else{ 
                                    objStatus.Session_Attendance_2__c += '<li>' +mapSessionDetail.get(sessionId).Name + '<b> &mdash; ' + AttendedCount + ' attended of 0 registered</b>'; 
                                }
                                
                                if(mapSessionIdRole.containskey(sessionId)){
                                    for(Session_Role__c objrole : mapSessionIdRole.get(sessionId)){
                                        if(roleName.contains(objrole.Role_Title__c)){
                                            objStatus.Session_Attendance_2__c += '<b>, ' + objrole.Number_of_Role__c + '  ' + objrole.Role_Title__c + '</b>';   
                                        }
                                    }
                                    objStatus.Session_Attendance_2__c += '</li>';
                                }
                            }
                            objStatus.Session_Attendance_2__c += '</ul>';
                        }
                    }
                } 
            }else{
                listOfSession = [SELECT id,Event__c,Session_Location__r.Name,Session_Location__c,Start_Date_Time__c,Name 
                                 FROM Session__c 
                                 WHERE Event__c IN :mapEvtIdReportId.keySet() AND IsActive__c=true and Start_Date_Time__c>:statusreportdate AND Start_Date_Time__c<:statusreportdate1 order by Start_Date_Time__c desc];
                for(Session__c ObjSession : listOfSession){
                    
                    if(!statusReportIdSessionLocation.containsKey(mapEvtIdReportId.get(ObjSession.Event__c))){
                        statusReportIdSessionLocationName.put(mapEvtIdReportId.get(ObjSession.Event__c),new Set<String>());
                        statusReportIdSessionLocation.put(mapEvtIdReportId.get(ObjSession.Event__c),new Set<Id>());
                    }
                    statusReportIdSessionLocationName.get(mapEvtIdReportId.get(ObjSession.Event__c)).add(ObjSession.Session_Location__r.Name);
                    statusReportIdSessionLocation.get(mapEvtIdReportId.get(ObjSession.Event__c)).add(ObjSession.Session_Location__c);
                }
                
                
            }
            for(Status_Report__c strReport : triggerNew){
                
                if(statusReportIdSessionLocation.size()<1 && strReport.Session_Location__c!=null){
                    strReport.addError('Please select session location available on above event and status report date');
                    break;
                }
                if(strReport.Session_Location__c!=null && statusReportIdSessionLocation.containsKey(strReport.id) && !statusReportIdSessionLocation.get(strReport.id).contains(strReport.Session_Location__c)){
                    string errorStr = '';
                    for(String s : statusReportIdSessionLocationName.get(strReport.id)){
                        if(s!=null){
                          errorStr +=s+',';   
                        }
                    }
                    strReport.Session_Location__c.addError('Please select session location available on above event from '+errorStr);
                }
                
            }
        } 
    }    
}