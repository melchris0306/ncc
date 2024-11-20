({
    //Leif START
    // the function that reads the url parameters
    getUrlParameter : function(sParam) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
        
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if (sParam == 'id') {
                if (sParameterName[0] === sParam && sParameterName[1].length >= 15) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                } else if (sParameterName[1] === sParam && sParameterName[2].length >= 15) {
                    return sParameterName[2] === undefined ? true : sParameterName[2];
                }
            } else {
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                } 
            }
        }
    },

    setDefaultMonthDate : function(component){
        let today = new Date();
        const currentMonthDate = $A.localizationService.formatDate(today, "MMMM yyyy");
        component.set('v.monthDate', currentMonthDate);
        component.set('v.selectedDate', today);
    },
    
    updateMonthDate : function(component, helper, addSubtractMonth){
        component.set('v.isLoading', true);
        let today = new Date();
        // adding or subtracting month
        let selectedDate = component.get('v.selectedDate');
        selectedDate = helper.addMonths(selectedDate, addSubtractMonth);
        if(today.getMonth() === selectedDate.getMonth() && today.getFullYear() === selectedDate.getFullYear()){
            component.set('v.isCurrentMonth', true);
            selectedDate.setDate(today.getDate());
        }
        else{
            component.set('v.isCurrentMonth', false);
            selectedDate.setDate(1);
        }
        component.set('v.selectedDate', selectedDate);

        // displaying month date
        const currentMonthDate = $A.localizationService.formatDate(selectedDate, "MMMM yyyy");
        component.set('v.monthDate', currentMonthDate);
        console.log('currentMonthDate');
        console.log(currentMonthDate);

        helper.getEvents(component, helper);
    },

    getEvents : function(component, helper) {
        let url_string = document.location.href;
        const urlParams = new URLSearchParams(url_string);
        const contactId = urlParams.get('contactId');
        const navigatorId = helper.getUrlParameter('id');

        let currDate = component.get('v.selectedDate');
        const year = currDate.getFullYear();
        const month = currDate.getMonth() + 1;
        const day = currDate.getDate();
        const currDateObj = {day, month, year, currDate};
                             
                                               
        console.log(navigatorId);
        console.log(year);                     
        console.log(month);                     
        console.log(day);                     
        console.log(currDateObj);                    
        console.log(contactId);

        const action = component.get('c.getEventsAndSessions');
        action.setParams({ contactId, month, year, navigatorId });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                let eventsWithSessions = response.getReturnValue();
                helper.displayEventsAndSessions(component, helper, eventsWithSessions, currDateObj);
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },

    displayEventsAndSessions : function(component, helper, eventsWithSessions, currDateObj){
        let eventsToDisplay = [];

        let today = new Date();
        today.setHours(0,0,0,0);
        console.log(eventsWithSessions);
        if(eventsWithSessions){
            currDateObj.currDate.setHours(0,0,0,0);
            const daysInMonth = helper.getDaysInMonth(currDateObj.month, currDateObj.year);
            try{
                // Day Loop
                for(let i=currDateObj.day; i<=daysInMonth; i++){
                    // setup date for the current iteration
                    console.log(currDateObj);
                    console.log(currDateObj.currDate);
                    let iDate = new Date(new Date(currDateObj.year, currDateObj.month-1, i).toLocaleString('en', {timeZone: 'America/New_York'}));
                    console.log(iDate);
                    console.log(new Date(currDateObj.currDate));
                    iDate.setHours(0,0,0,0);
                    let displayDate = $A.localizationService.formatDate(iDate, "dd EEE");
                    let dateString = displayDate.split(' ');
                    let dateNumber = dateString[0];
                    let dayOfTheWeek = dateString[1].toUpperCase();
                    let eventsOfTheDay = [];
                    // Background Color CSS
                    const todayStr = today.getDate() + '/' + today.getMonth() + '/' + today.getFullYear();
                    const iDateStr = iDate.getDate() + '/' + iDate.getMonth() + '/' + iDate.getFullYear();
                    let backgroundColor = todayStr === iDateStr ? 'event-today' : 'event-upcoming';

                    // Event Loop
                    eventsWithSessions.forEach(function(eventSessionWrap){
                        let sessions = [];
                            // Session Loop
                            if(eventSessionWrap.sessions && eventSessionWrap.sessions.length){
                                eventSessionWrap.sessions.forEach(function(session){

                                    let sessionStartDate = new Date(new Date(session.startDateTime).toLocaleString('en', {timeZone: 'America/New_York'})); //new Date(session.startDateTime);
                                    let sessionEndDate = new Date(new Date(session.endDateTime).toLocaleString('en', {timeZone: 'America/New_York'})); //new Date(session.endDateTime);
                                    //let eventStartDate = new Date(eventSessionWrap.event.startDateTime);
                                    sessionStartDate.setHours(0,0,0,0);
                                    sessionEndDate.setHours(0,0,0,0);
                                    
                                    console.log('sessions');
                                    //console.log(sessionStartDate <= iDate);
                                    //console.log(sessionEndDate >= iDate);
                                    if(sessionStartDate <= iDate && sessionEndDate >= iDate){
                                    //if(sessionEndDate >= iDate){
                                        sessions.push(session);
                                    } 
                                });
                                
                                let eventEndDate = new Date(new Date(eventSessionWrap.event.endDateTime).toLocaleString('en', {timeZone: 'America/New_York'}));
                                let eventStartDate = new Date(new Date(eventSessionWrap.event.startDateTime).toLocaleString('en', {timeZone: 'America/New_York'}));
                                
                                if(sessions.length){
                                    console.log('sessions if');
                                    let eventObj = { event : eventSessionWrap.event, sessions };
                                    eventsOfTheDay.push(eventObj);
                                } else if(eventStartDate <= iDate && eventEndDate >= iDate){
                                    console.log('sessions else if');
                                    eventSessionWrap.event.startTime = helper.formatAMPM(eventSessionWrap.event.startDateTime);
                                    eventSessionWrap.event.endTime = helper.formatAMPM(eventSessionWrap.event.endDateTime);
                                    let eventObj = { event : eventSessionWrap.event, sessions : null , isSingleEvent : eventSessionWrap.isSingleEvent };
                                    eventsOfTheDay.push(eventObj);
                                }
                            }
                            //else if(eventSessionWrap.isSingleEvent){
                            else {
                                console.log('Event else');
                                let eventStartDate = new Date(new Date(eventSessionWrap.event.startDateTime).toLocaleString('en', {timeZone: 'America/New_York'}));
                                let eventEndDate = new Date(new Date(eventSessionWrap.event.endDateTime).toLocaleString('en', {timeZone: 'America/New_York'}));
                                eventStartDate.setHours(0,0,0,0);
                                eventEndDate.setHours(0,0,0,0);
                                if(eventStartDate <= iDate && eventEndDate >= iDate){
                                //if(eventEndDate >= iDate){
                                    eventSessionWrap.event.startTime = helper.formatAMPM(eventSessionWrap.event.startDateTime);
                                    eventSessionWrap.event.endTime = helper.formatAMPM(eventSessionWrap.event.endDateTime);
                                    let eventObj = { event : eventSessionWrap.event, sessions : null , isSingleEvent : eventSessionWrap.isSingleEvent };
                                    eventsOfTheDay.push(eventObj);
                                }
                            }
                    });
                    if(eventsOfTheDay.length) eventsToDisplay.push({ dateNumber, dayOfTheWeek, eventsOfTheDay, backgroundColor });
                }
                component.set('v.events', eventsToDisplay);
                console.log(eventsToDisplay);
                component.set('v.isLoading', false);
            }
            catch(e){
                console.log('error: ' + e.message);
            }
        }
    },

    getDaysInMonth : function(month,year) {
       return new Date(year, month, 0).getDate();
    },
    
    addMonths : function(date, months) {
        var d = date.getDate();
        date.setMonth(date.getMonth() + +months);
        if (date.getDate() != d) {
          date.setDate(0);
        }
        return date;
    },

    formatAMPM : function(dateStr) {
        let timeStr = dateStr.split('T')[1];
        let splittedTime = timeStr.split(':');
        let hours = parseInt(splittedTime[0]);
        let minutes = parseInt(splittedTime[1]);
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0'+minutes : minutes;
        var strTime = hours + ':' + minutes + ' ' + ampm;
        return strTime;
    },
      
    showToastError : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": message
        });
        toastEvent.fire();
    },

    logError : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                let errorMessage = "Error message: " + errors[0].message
                console.log(errorMessage);
                return errorMessage;
            }
            else{
                console.log("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.log("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},
})