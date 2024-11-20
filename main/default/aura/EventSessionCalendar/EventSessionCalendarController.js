({
    created : function(component, event, helper) {
        helper.created(component, event);
    },
    
    renderCalendar : function(component, event, helper) {
        helper.pullRecId(component, event);
        var eventsMap = component.get("v.events");
        
        $(document).ready(function(){
            var eventArray = [];
            $.each(eventsMap, function(index, value){
                if(component.get('v.eventRecId') == null){
                    component.set('v.eventRecId', value.eventRecId);
                }
                
                var startDateTimeNew = new Date(value.startDateTime);
                var endDateTimeNew = new Date(value.endDateTime);
                var startDatetime_Start = moment(startDateTimeNew.toLocaleString('en-US', { timeZone: value.commonTimezone})).format();
                var startDatetime_End = moment(endDateTimeNew.toLocaleString('en-US', { timeZone: value.commonTimezone})).format();
				                
                // Start CCN-2192 25-10-2022: Von Pernicia - Comment out code
                /* var startDatetime_Start = moment(value.startDateTime).format();
                var startDatetime_End = moment(value.endDateTime).format();
                var final_dateRecord_start;
                var final_dateRecord_end; */
                
                // Converting to Date
                /* const startDateStart_TemporaryVariable = new Date(startDatetime_Start);
                const endDataStart_TemporaryVariable = new Date(startDatetime_End); */
                // Initial checking of the timezon offset for start and end date.
                /* let DateJanuaryTimeOffset_start = new Date(startDateStart_TemporaryVariable.getFullYear(), 0, 1).getTimezoneOffset();
    			let DateJulyTimeOffset_start = new Date(startDateStart_TemporaryVariable.getFullYear(), 6, 1).getTimezoneOffset();
                let DateJanuaryTimeOffset_end = new Date(endDataStart_TemporaryVariable.getFullYear(), 0, 1).getTimezoneOffset();
    			let DateJulyTimeOffset_end = new Date(endDataStart_TemporaryVariable.getFullYear(), 6, 1).getTimezoneOffset(); */
				
                // This is to check if the inputted date is belong to Daylight Saving or not For the Start Date
                /* if(Math.max(DateJanuaryTimeOffset_start, DateJulyTimeOffset_start) != startDateStart_TemporaryVariable.getTimezoneOffset()){
                    //console.log(' not DST = ' + moment(value.startDateTime).add(-4, 'hours').utc().format());
                    // This is the final Date Record for Startdate in the view
                    final_dateRecord_start = moment(value.startDateTime).add(-4, 'hours').utc().format();
                    component.set('v.isDST', false);
                }else{
                    //console.log(' this is DST = ' + date4);
                    //console.log(' this is DST = ' + moment(value.startDateTime).add(-5, 'hours').utc().format());
                    // This is the final Date Record for Startdate in the view
                    final_dateRecord_start = moment(value.startDateTime).add(-4, 'hours').utc().format();
                    component.set('v.isDST', true);
                }
                
                // This is to check if the inputted date is belong to Daylight Saving or not For the End Date
                if(Math.max(DateJanuaryTimeOffset_end, DateJulyTimeOffset_end) != endDataStart_TemporaryVariable.getTimezoneOffset()){
                    //console.log(' not DST = ' + moment(value.endDateTime).add(-4, 'hours').utc().format());
                    // This is the final Date Record for Enddate in the view
                    final_dateRecord_end = moment(value.endDateTime).add(-4, 'hours').utc().format();
                }else{
                    //console.log(' this is DST = ' + date4);
                    //console.log(' this is DST = ' + moment(value.endDateTime).add(-5, 'hours').utc().format());
                    // This is the final Date Record for Enddate in the view
                    final_dateRecord_end = moment(value.endDateTime).add(-4, 'hours').utc().format();
                } */
                // End of additional Code by DinoBtinas [CCN-921]
                // End CCN-2192 25-10-2022: Von Pernicia - Comment out code
                // Added by DinoBrinas [CCN1039] Dec032021
                component.set('v.dateDisabled', false);
                
                var newEvent = {
                    id : value.Id,
                    trueTitle : value.title,
                    //Added by RRizarri [CCN-2620] Mar102023
                    status : value.status,
                    //End [CCN-2620] Mar102023
                    location: value.location,
                    title : value.title + ' | ' + value.status,
                    timezoneAbbr : value.timezoneAbbr,
                    //start : moment(value.startDateTime).format(),
                    //start: moment(value.startDateTime).add(-4, 'hours').utc().format(),
                    start: startDatetime_Start, // Start/End CCN-2192 25-10-2022: Von Pernicia
                    //end : moment(value.endDateTime).format(),
                    end : startDatetime_End, // Start/End CCN-2192 25-10-2022: Von Pernicia
                    description : value.description,
                    owner : value.owner
                }
                eventArray.push(newEvent);
            });
            var calendarButtons = component.get('v.calendarButtons');
            $('#calendar').fullCalendar({
                header: {
                    left: 'today prev,next',
                    center: 'title',
                    right: calendarButtons
                },
                defaultDate: component.get('v.defaultDate'),
                navLinks: true, // can click day/week names to navigate views
                editable: true,
                eventLimit: true, // allow "more" link when too many events
                weekends: component.get('v.weekends'),
                eventOrder: "title,-duration",
                eventOrderStrict: true,
                eventBackgroundColor: component.get('v.eventBackgroundColor'),
                eventBorderColor: component.get('v.eventBorderColor'),
                eventTextColor: component.get('v.eventTextColor'),
                events: eventArray,
                timezone: 'EDT', // Start/End CCN-2192 25-10-2022: Von Pernicia // Where is this used?
                eventClick: function(calEvent, jsEvent, view) {
                    // Opens Edit Session
                    component.set('v.locationVal', '');
                    component.set('v.titleVal', calEvent.trueTitle);
                    component.set('v.descriptionVal', calEvent.description);
                    component.set('v.startDateTimeVal', moment(calEvent.start._d).utc().format()); // Start/End CCN-2192 25-10-2022: Von Pernicia
                    component.set('v.endDateTimeVal', moment(calEvent.end._d).utc().format()); // Start/End CCN-2192 25-10-2022: Von Pernicia
                    component.set('v.idVal', calEvent.id);
                    component.set('v.timezoneAbbr', calEvent.timezoneAbbr);
                    
                    // CCN-EVE-3113-DV - Gian: added date, startTime and endTime to accomodate for the new UI based on the current data set of the session
                    component.set('v.date', moment(calEvent.start._d).utc().format('YYYY-MM-DD'));
                    component.set('v.startTime', moment(calEvent.start._d).utc().format('HH:mm:ss'));
                    component.set('v.endTime', moment(calEvent.end._d).utc().format('HH:mm:ss'));
                    
                    //Added by RRizarri [CCN-2620] Mar102023
                    component.set('v.statusVal', calEvent.status);
                    //End [CCN-2620] Mar102023
                    component.set('v.newOrEdit', 'Edit');
                    component.set('v.titleDisabled', true);
                    component.set('v.locationVal', calEvent.location);
   
                    // Added by DinoBrinas [CCN1039] Dec032021
                    if(calEvent.title.includes("| Approved")){
                        //calEvent.editable = false;
                        //calEvent.resourceEditable = false; 
                        component.set('v.dateDisabled', true);
                    }else{
                        component.set('v.dateDisabled', false);
                    }
                    // End of Additional code [CCN1039]
                    helper.openModal(component, event);
                },
                
                eventMouseover: function(event, jsEvent, view){
					if(event.title.includes("| Approved")){
                        event.editable = false;
                        event.resourceEditable = false;
                        // Added By JaysonLabnao  09/06/22 [CCN-2117]
                        $A.util.removeClass(jsEvent.currentTarget, 'fc-allow-mouse-resize');
                    }
                },
                
                // Start CCN-2192 25-10-2022: Von Pernicia - updated parameters
                eventDrop: function(event, delta, revertFunc) {
        			var isDST = component.get('v.isDST');
                    var evObj = {
                        "Id" : event.id,
                        "title" : event.title,
                        "startDateTime" : moment(event.start._d).utc().format(),
                        "endDateTime" : moment(event.end._d).utc().format(),
                        //"startDateTime" : moment(event.start._i).add(isDST?5:4, 'hours').add(delta).format(),
                        //"endDateTime" : moment(event.end._i).add(isDST?5:4, 'hours').add(delta).format(),
                        "description" : event.description,
                        "location" : event.location
                    };
                    console.log('eventDrop');
                    helper.upsertEvent(component, evObj);
                },
                eventResize: function(event, delta, revertFunc) {
                    var evObj = {
                        "Id" : event.id,
                        "title" : event.title,
                        //"startDateTime" : moment(event.start._i).format(),
                        //"endDateTime" : moment(event.end._i).add(delta).format(),
                        //"startDateTime" : moment(event.start._i).add(4, 'hours').format(),
                        //"endDateTime" : moment(event.end._i).add(4, 'hours').add(delta).format(),
                        "startDateTime" : moment(event.start._i).add(delta).utc().format(),
                        "endDateTime" : moment(event.end._i).add(delta).utc().format(),
                        "description" : event.description
                    };
                    console.log(evObj.startDateTime);
                    console.log(evObj.endDateTime);
                    console.log('eventResize');
                    helper.upsertEvent(component, evObj);
                },
                // End CCN-2192 25-10-2022: Von Pernicia - updated parameters
                dayClick: function(date, jsEvent, view) {
                    // Open new session
                    component.set('v.idVal', null),
                    component.set('v.titleVal', '');
                    component.set('v.locationVal', '');
                    component.set('v.titleDisabled', false);
                    component.set('v.timezoneAbbr', '');
                    
                    // CCN-EVE-3113-DV - Gian: Added default for statusVal and dateDisabled for new UI
                    // Set default value for statusVal and dateDisabled 
                    // Default value is based on existing logic
                    component.set('v.statusVal', 'Proposed');
                    component.set('v.dateDisabled', false); 
                    //component.set('v.timezoneVal', 'EST');
					
                    // Grabs the even'ts timezone
                    helper.getEventTimezone(component);
                    
                    var startDateTimeValue;
                    var endDateTimeValue;

                    if (date._f == "YYYY-MM-DD"){
                        //component.set('v.startDateTimeVal', moment(date).format());
                        //component.set('v.endDateTimeVal', moment(date).format());
                        //component.set('v.startDateTimeVal', date.format() + 'T00:00:00');
                        //component.set('v.endDateTimeVal', date.format()  + 'T02:00');
                        startDateTimeValue = date.format() + 'T08:00:00';
                        endDateTimeValue = date.format() + 'T10:00:00';
                    } else {
                        //component.set('v.startDateTimeVal', moment(date.format()).format());
                        //component.set('v.endDateTimeVal', moment(date.format()).add(2, 'hours').format());
                        startDateTimeValue = date.utc().format();
                        endDateTimeValue = date.add(2, 'hours').utc().format();
                    }
                    
                    component.set('v.startDateTimeVal', startDateTimeValue);
                    component.set('v.endDateTimeVal', endDateTimeValue);
                    
                     // CCN-EVE-3113-DV - Gian: set the correct date, startTime and endTime as default values for a new session
                    component.set('v.date', moment(date).format('YYYY-MM-DD'));
                    component.set('v.startTime', moment(startDateTimeValue).format('HH:mm:ss')); // Default value
                    component.set('v.endTime', moment(endDateTimeValue).format('HH:mm:ss')); // Default value
                    component.set('v.newOrEdit', 'New');
                    
                    helper.openModal(component, event);
                }, 

                // UPDATED by JC ESPINO [CCN-EVE-2870-DV] MAY222023 - Updated to add Time Zone to Session Tile in Calendar
                eventRender: function(event, element) {
                    element.find('.fc-time')
                    .append('<span class="fc-time"> ' + 
                        event.timezoneAbbr + '</span>'
                    );
                }
            });
        });
    },
   
    createRecord : function(component, event, helper) {
        // CCN-EVE-3113-DV - Gian: Grab date, startTime and endTime values and combine them to startDateTime and endDateTime
        // to acommodate new UI values and save them in the correct dateTime format for the backend
        var date = component.get('v.date');
        var startTime = component.get('v.startTime');
        var endTime = component.get('v.endTime');
        var startDateTime = moment.utc(date + 'T' + startTime).toISOString();
        var endDateTime = moment.utc(date + 'T' + endTime).toISOString();
      
        // CCN-EVE-3113-DV - Gian: set new toast error
        // Shows a toast event error when End time is greater than the start time
        if (endDateTime <= startDateTime) {
           // End time is greater than the start time
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams({
               type: 'error',
               mode: 'pester',
               duration:'8000',
               message: 'Please enter an End Time that is greater than the Start Time.' 
           });
           toastEvent.fire();
        } else {
          // End time is not greater than the start time
          var evObj = {
            "title" : component.get('v.titleVal'),
            // "startDateTime" : moment(component.get('v.startDateTimeVal')).utc().format(),  // Start/End CCN-2192 25-10-2022: Von Pernicia - updated parameters
            // "endDateTime" : moment(component.get('v.endDateTimeVal')).utc().format(),  // Start/End CCN-2192 25-10-2022: Von Pernicia - updated parameters
            "description" : component.get('v.descriptionVal'),
            "location" : component.get('v.locationVal'),
            "timezoneAbbr": component.get('v.timezoneAbbr'),
            "startDateTime": startDateTime,
            "endDateTime": endDateTime
        };
        
        if (component.get('v.idVal')) {
            evObj.id = component.get('v.idVal');
            $('#calendar').fullCalendar( 'removeEvents', component.get('v.idVal') );
        }
        
        if (evObj.id == null) {
            // Added by RLugpatan [CCN-1110] 08.Jan.2022
            if(component.get('v.titleVal') == ''){
                component.set("v.isSaving", false); 
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Missing Required Field',
                    type: 'error',
                    mode: 'pester',
                    duration:' 8000',
                    message: 'Please provide the Title before saving the new session.' 
                });
                toastEvent.fire();
            // End of Additional code [CCN-1110]
            } else{
                // New Session
                component.set("v.isSaving", true); //Added for [CCN-1110] 14.Jan.2022
                helper.insertEvent(component, evObj, function(response) {
                    var state = response.getState();
                    
                    if (state === "SUCCESS") {
                        helper.saveAndRefresh(component, evObj);
                        //component.set("v.isSaving", false); 
                    } else if (state === "INCOMPLETE") {
                        // do something
                    } else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
                });
            }
        } else{ 
            // Session Edit
            helper.upsertEvent(component, evObj, function(response){
                var state = response.getState();
  
                if (state === "SUCCESS") {
                    helper.saveAndRefresh(component, evObj);
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
            });
        }
        }
    },
    deleteRecord : function(component, event, helper) {
        helper.deleteEvent(component, event, event.getSource().get("v.value"), function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                $('#calendar').fullCalendar( 'removeEvents', response.getReturnValue());
                helper.closeModal(component, event);
                component.set('v.titleVal','');
                component.set('v.idVal','');
                component.set('v.startDateTimeVal','');
                component.set('v.endDateTimeVal','');
                component.set('v.descriptionVal','');
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
    },
    closeModal : function(component, event, helper) {
        helper.closeModal(component, event);
    },
    signUpRoles : function(component,event,helper){
        helper.openMassSessionPage(component,event);
    },
    saveProposedRecord : function(component, event, helper){
		helper.saveAndRefresh(component, event);
    },
})