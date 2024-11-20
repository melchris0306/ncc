({
    //MMALLORCA 03/07/2024 CCN-JOU-3713-DV
    handleOnClick: function(component, event, helper) {
        helper.handleOnClick(component, event, helper);
    },
    finish: function(component, event, helper) {
        //console.log('finish');
        component.set("v.spinner", true);

        var finishEvt = event;
        var quickCheckId = finishEvt.target.value;
        //console.log('quickCheck' + quickCheckId);
        helper.handleFinish(component, event, helper, quickCheckId);
        window.setTimeout(
            $A.getCallback(function() {
                var action = component.get('c.doInit');
                $A.enqueueAction(action);
                component.set("v.spinner", false);
            }), 3000
        );
    },

    //Submit Button
    validate: function(component, event, helper) {
        const curQuestToValidate = component.get("v.curQuestToValidate");
        //console.log('curQuestToValidate' + JSON.stringify(curQuestToValidate));
        helper.validateAnswer(component, event, helper, curQuestToValidate);
    },

    beginQuestion: function(component, event, helper) {
        //console.log('beginQuestion');

        var quickCheckEvt = event;
        var quickCheck = quickCheckEvt.target.value;
        //console.log('quickCheck' + quickCheck);

        var questionGrid = document.getElementById(quickCheck + 'question-grid');
        questionGrid.classList.remove("none");

        var beginBtn = document.getElementById(quickCheck + 'begin-btn');
        beginBtn.classList.add("none");

        var submitBtn = document.getElementById(quickCheck + 'submit-btn');
        submitBtn.classList.remove("none");
        submitBtn.disabled = true;

        var qcId = quickCheck;
        component.set("v.curQuickCheck", qcId);
        //console.log('qcId>>>' + qcId);
        var qcq = component.get("v.quickCheckQuestions");
        //console.log('qcq>>>' + JSON.stringify(qcq));

        var quesList;
        for (var i = 0; i < qcq.length; i++) {
            console.log(i + '-i-' + qcq[i].key);
            if (qcId == qcq[i].key) {
                quesList = qcq[i].value;
            } else {
                var beginBtn = document.getElementById(qcq[i].key + 'begin-btn');
                if (beginBtn) {
                    beginBtn.classList.remove("none");
                    beginBtn.disabled = false;
                }
                var submitBtn = document.getElementById(qcq[i].key + 'submit-btn');
                if (submitBtn) {
                    submitBtn.classList.add("none");
                    submitBtn.classList.remove("display");
                }
                var nextBtn = document.getElementById(qcq[i].key + 'next-btn');
                if (nextBtn) {
                    nextBtn.classList.add("none");
                    nextBtn.classList.remove("display");
                }
                var finishtBtn = document.getElementById(qcq[i].key + 'finish-btn');
                console.log('finishtBtn' + finishtBtn);
                if (finishtBtn) {
                    finishtBtn.classList.add("none");
                    finishtBtn.classList.remove("display");
                    finishtBtn.disabled = true;
                }
            }
        }
        //enable all question options 
        var quesInput = document.getElementsByClassName(qcId);
        //console.log('quesInput' + quesInput);
        //console.log('quesInput' + quesInput.length);
        if(quesInput){
            for (var i = 0; i < quesInput.length; i++) {
                quesInput[i].disabled = false;
                if (quesInput[i].type == "checkbox" || quesInput[i].type == "radio") {
                    quesInput[i].checked = false;
                }
            }
        }

        var qOrder = new Map();
        var qqOrder = component.get("v.quickCheckQuesOrder");
        var curOrder;
        //console.log('qqOrder>>'+JSON.stringify(qqOrder));

        //number of questions in quick check quesList
        /*console.log('quesList>>>' + JSON.stringify(quesList.length));
        console.log('>>>' + quesList[qOrder.get(qcId)]);
        console.log('>>>' + qOrder.get(qcId));*/

        if (qqOrder != null) {
            if (qqOrder.get(qcId) != undefined || qqOrder.get(qcId) != null) {
                curOrder = parseInt(qqOrder.get(qcId) + 1);
                qOrder.set(qcId, curOrder);
                component.set("v.quickCheckQuesOrder", qOrder);
            } else {
                curOrder = 0;
                console.log('curOrder>' + curOrder);
                qOrder.set(qcId, 0); //first question
                component.set("v.quickCheckQuesOrder", qOrder);
            }
        }
        //First Question
        else {
            curOrder = 0;
            //console.log('curOrder>' + curOrder);
            qOrder.set(qcId, 0); //first question
            component.set("v.quickCheckQuesOrder", qOrder);
        }
        //if last question
        if (quesList.length == parseInt(curOrder + 1)) {
            //Enable Next button
            var nextBtn = document.getElementById(qcId + 'next-btn');
            if(nextBtn){
                nextBtn.classList.add("none");
            }
            //Finish
            var finishBtn = document.getElementById(qcId + 'finish-btn');
            if(finishBtn){
                finishBtn.classList.add("display");
            }
            quesList[curOrder].LastQuestion = qcId + "LastQuestion";
        } else {
            //Enable Next button
            var nextBtn = document.getElementById(qcId + 'next-btn');
            if(nextBtn){
                nextBtn.disabled = true;
            }
        }
        //console.log('curOrder>'+curOrder);
        //console.log('curOrder>'+JSON.stringify(component.get("v.quickCheckQuesOrder")));
        //console.log('curQuestion>'+JSON.stringify(quesList[curOrder]));

        if (quesList.length > curOrder) {
            quesList[curOrder].QuestionCtr = "Question " + parseInt(curOrder + 1) + ": ";
            component.set("v.curQuestion", quesList[curOrder]);
        } 
        
        component.set("v.curQuestToValidate", quesList[curOrder]);
    },

    doInit: function(component, event, helper) {
        var url = new URL(window.location.href);

        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split("&"); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split("="); //to split the key from the value.

            if (sParameterName[i] === "journeyId") {
                //sParameterName[1] === undefined ? 'Not found' : sParameterName[1];
                component.set("v.journeyID", sParameterName[1]);
            }
        }

        var journeyId;

        if (component.get("v.journeyID") == null) {
            journeyId = "a5J03000000L08NEAS";
        } else {
            journeyId = component.get("v.journeyID");
        }

        console.log("!@# journeyID: " + journeyId);

        //CCN-2291 XenReyes Nov2022
        helper.getUserJourney(component, journeyId, helper);
    },

    handleSurveyCompletion: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.updateParticipantMilestoneMetric(component, event, helper);
    },

    handleEventCatchUp: function(component, event, helper) {
        component.set("v.spinner", true);
        helper.updateParticipantEventMetric(component, event, helper);
    }
});