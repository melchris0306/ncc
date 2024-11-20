({
    created : function(component, event, helper) {
        helper.created(component, event);
    },
    
    renderCalendar : function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);  
        var campaignId = (queryString.split('id=')[1]).split('&')[0];
        var eventsMap = component.get("v.events");
        //Start [CCN-EVE-2173-DV] MelMallorca Nov262022
        $('#calendar').fullCalendar('destroy');
        $('#calendar').fullCalendar('render');
        //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        $(document).ready(function(){
            var eventArray = [];
            $.each(eventsMap, function(index, value){
                if(component.get('v.eventRecId') == null){
                    component.set('v.eventRecId', campaignId);
                }
                var startDatetime_Start = moment(value.startDateTime).format();
                var startDatetime_End = moment(value.endDateTime).format();
                var final_dateRecord_start;
                var final_dateRecord_end;
                const startDateStart_TemporaryVariable = new Date(startDatetime_Start);
                const endDataStart_TemporaryVariable = new Date(startDatetime_End);
                let DateJanuaryTimeOffset_start = new Date(startDateStart_TemporaryVariable.getFullYear(), 0, 1).getTimezoneOffset();
                let DateJulyTimeOffset_start = new Date(startDateStart_TemporaryVariable.getFullYear(), 6, 1).getTimezoneOffset();
                let DateJanuaryTimeOffset_end = new Date(endDataStart_TemporaryVariable.getFullYear(), 0, 1).getTimezoneOffset();
                let DateJulyTimeOffset_end = new Date(endDataStart_TemporaryVariable.getFullYear(), 6, 1).getTimezoneOffset();
                if(Math.max(DateJanuaryTimeOffset_start, DateJulyTimeOffset_start) != startDateStart_TemporaryVariable.getTimezoneOffset()){
                    final_dateRecord_start = moment(value.startDateTime).add(-4, 'hours').utc().format();
                    component.set('v.isDST', false);
                }else{
                    final_dateRecord_start = moment(value.startDateTime).add(-5, 'hours').utc().format();
                    component.set('v.isDST', true);
                }
                if(Math.max(DateJanuaryTimeOffset_end, DateJulyTimeOffset_end) != endDataStart_TemporaryVariable.getTimezoneOffset()){
                    final_dateRecord_end = moment(value.endDateTime).add(-4, 'hours').utc().format();
                }else{
                    final_dateRecord_end = moment(value.endDateTime).add(-5, 'hours').utc().format();
                }
                component.set('v.dateDisabled', false);
                var newEvent = {
                    id : value.Id,
                    trueTitle : value.title,
                    status : value.status,
                    location: value.location,
                    title : value.title + ' | ' + value.status,
                    start: final_dateRecord_start,
                    end : final_dateRecord_end,
                    description : value.description,
                    owner : value.owner
                }
                eventArray.push(newEvent);
            });
            var calendarButtons = component.get('v.calendarButtons');
            var today = new Date();
            var dd = String(today.getDate()).padStart(2, '0');
            var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
            var yyyy = today.getFullYear();
            var currentDate = yyyy + '-' + mm + '-' + dd;
            
            $('#calendar').fullCalendar({
                header: {
                    left: 'today prev,next',
                    center: '',
                    right: 'title',calendarButtons
                },
                    defaultDate: currentDate,
                    navLinks: true, 
                    editable: false,
                    eventLimit: true,
                    //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
                    displayEventTime: false,
                    //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
                    weekends: component.get('v.weekends'),
                    eventOrder: "title,-duration",
                    eventOrderStrict: true,
                    eventBackgroundColor: component.get('v.eventBackgroundColor'),
                    eventBorderColor: component.get('v.eventBorderColor'),
                    eventTextColor: component.get('v.eventTextColor'),
                    events: eventArray,
                    timezone: 'PST',
                    eventClick: function(calEvent, jsEvent, view) {
                        component.set('v.locationVal', '');
                        component.set('v.titleVal', calEvent.trueTitle);
                        component.set('v.descriptionVal', calEvent.description);
                        component.set('v.startDateTimeVal', moment(calEvent.start._d).format());
                        component.set('v.endDateTimeVal', moment(calEvent.end._d).format());
                        component.set('v.idVal', calEvent.id);
                        component.set('v.newOrEdit', 'Edit');
                        component.set('v.titleDisabled', true);
                        component.set('v.locationVal', calEvent.location);
                        if(calEvent.title.includes("| Approved")){
                            component.set('v.dateDisabled', true);
                        }else{
                            component.set('v.dateDisabled', false);
                        }
                        //helper.openModal(component, event);
                    },
                    
                    eventMouseover: function(event, jsEvent, view){
                        if(event.title.includes("| Approved")){
                            event.editable = false;
                            event.resourceEditable = false;
                        }
                    },
                    
                    eventDrop: function(event, delta, revertFunc) {
                        var isDST = component.get('v.isDST');
                        var evObj = {
                            "Id" : event.id,
                            "title" : event.title,
                            "startDateTime" : moment(event.start._i).add(isDST?5:4, 'hours').add(delta).format(),
                            "endDateTime" : moment(event.end._i).add(isDST?5:4, 'hours').add(delta).format(),
                            "description" : event.description,
                            "location" : event.location
                        };
                        helper.upsertEvent(component, evObj);
                    },
                    eventResize: function(event, delta, revertFunc) {
                        var evObj = {
                            "Id" : event.id,
                            "title" : event.title,
                            "startDateTime" : moment(event.start._i).add(4, 'hours').format(),
                            "endDateTime" : moment(event.end._i).add(4, 'hours').add(delta).format(),
                            "description" : event.description
                        };
                        console.log(evObj.startDateTime);
                        console.log(evObj.endDateTime);
                        helper.upsertEvent(component, evObj);
                    },
                    dayClick: function(date, jsEvent, view) {
                        console.log('dayClick');
                        component.set('v.idVal', null),
                            component.set('v.titleVal', '');
                        component.set('v.locationVal', '');
                        component.set('v.titleDisabled', false);
                        component.set('v.timezoneVal', 'EST');
                        if (date._f == "YYYY-MM-DD"){
                            component.set('v.startDateTimeVal', date.format() + 'T08:00:00');
                            component.set('v.endDateTimeVal', date.format() + 'T10:00:00');
                        } else {
                            component.set('v.startDateTimeVal', date.utc().format());
                            component.set('v.endDateTimeVal', date.add(2, 'hours').utc().format());
                        }
                        component.set('v.newOrEdit', 'New');
                        //helper.openModal(component, event);
                    }
                });
            });
        },
                          
                          createRecord : function(component, event, helper) {
            
        },
            deleteRecord : function(component, event, helper) {
                
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