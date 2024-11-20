({
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : mode ? mode : "dismissible"
        });
        toastEvent.fire();
    },

    computeForSessionActive : function (helper, startDateTime, endDateTime, currentDateTime){
        let isActive = false;
        
        startDateTime.setMinutes(startDateTime.getMinutes() - 15);
        endDateTime.setMinutes(endDateTime.getMinutes() + 30);
        
        if (currentDateTime >= startDateTime && currentDateTime <= endDateTime){
            isActive = true;
        }
        
        var x = { /*Added for CCN-1070 Jan.15.2022*/
            sdt: startDateTime,
            edt: endDateTime,
            cdt: currentDateTime,
            active: isActive
        };
        console.log(x);
        
        return isActive;
    },

    isSameDateWithCurrent : function(dateValue, currentDateTime){
        return dateValue.getDate() === currentDateTime.getDate() 
            && (dateValue.getMonth() + 1) === (currentDateTime.getMonth() + 1) 
            && dateValue.getFullYear() === currentDateTime.getFullYear();
    },
    
    computeForSessionCatchUp : function (helper, startDateTime, endDateTime, currentDateTime){
        let isCatchupAvailable = false;
        startDateTime.setMinutes(startDateTime.getMinutes() - 15);
        endDateTime.setMinutes(endDateTime.getMinutes() + 30);
        
        if (currentDateTime >= startDateTime && currentDateTime <= endDateTime){
            isCatchupAvailable = true;
        }
        
        return isCatchupAvailable;
    },
})