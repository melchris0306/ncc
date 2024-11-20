({
    //MMALLORCA 03/07/2024 CCN-JOU-3713-DV
    result: {},

    handleFinish: function(component, event, helper, quickCheckId) {
        console.log('this.result:' + JSON.stringify(this.result));

        var finalRes = [];
        var ctr = 0;
        for (const [key, value] of Object.entries(this.result)) {
            console.log(`Key: ${key}, Value: ${JSON.stringify(value)}`);
            value.AnswerChecking = 'Incorrect';
            value.Answer = (value.Answer).toString();
            if (value.QuickCheckId == quickCheckId) {
                if (value.Answer == value.CorrectAnswers) {
                    value.AnswerChecking = 'Correct';
                }
                ctr++;
                value.counter = JSON.stringify(ctr);
                finalRes.push(value);
            }
        }
        component.set("v.finalResult", finalRes);

        var saveAnswers = component.get("c.saveAnswers");
        saveAnswers.setParams({
            finalRes: JSON.stringify(finalRes)
        });

        saveAnswers.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state ::: ', state);

            console.log(response.getError());

            if (state === "SUCCESS") {
                var result = helper.cleanUpNamespace(response.getReturnValue());
            } else if (state = "ERROR") {
                console.log(response.getError()[0]);
            }
        });
        $A.enqueueAction(saveAnswers);

        var finishtBtn = document.getElementById(quickCheckId + 'finish-btn');
        if (finishtBtn) {
            finishtBtn.classList.add("none");
            finishtBtn.classList.remove("display");
            finishtBtn.disabled = true;
        }
    },

    //Update survey answers upon input
    validateAnswer: function(component, event, helper, curQues) {
        //console.log('this.result:' + JSON.stringify(this.result));
        //console.log('curQues:' + JSON.stringify(curQues));

        var curQuesId = curQues.Id;
        var quickcheckId = curQues.Quick_Check__c;
        const result = this.result[curQuesId];

        if (this.result[curQuesId]) {
            const answer = String(result.Answer).trim();
            const correctAnswers = result.CorrectAnswers;
            
            
            console.log('Answer----' + answer);
            console.log('CorrectAnswers----' + correctAnswers);
            var resultDiv;
            var resultAns;
            //Correct Answer
            if (answer == correctAnswers) {
                
                resultDiv = document.getElementById(curQuesId + "result-div-correct");
                if (resultDiv) {
                    resultDiv.classList.remove("none");
                    resultDiv.classList.add("display");
                }
                
                resultAns = document.getElementById(curQuesId + "result-correct");
                if (resultDiv) {
                    resultAns.innerHTML = (curQues.Correct_Answer_Message__c != undefined ? curQues.Correct_Answer_Message__c : '');
                }

                resultDiv = document.getElementById(curQuesId + "answer-list-div-incorrect");
                if (resultDiv) {
                    resultDiv.classList.remove("display");
                    resultDiv.classList.add("none");
                }

                resultDiv = document.getElementById(curQuesId + "answer-list-div-val-incorrect");
                if (resultDiv) {
                    resultDiv.classList.remove("display");
                    resultDiv.classList.add("none");
                }
            }
            //Incorrect Answer
            else {
                
                resultDiv = document.getElementById(curQuesId + "result-div-incorrect");
                if (resultDiv) {
                    resultDiv.classList.remove("none");
                    resultDiv.classList.add("display");
                }
                
                resultAns = document.getElementById(curQuesId + "result-incorrect");
                if (resultDiv) {
                    resultAns.innerHTML = (curQues.Incorrect_Answer_Message__c != undefined ? curQues.Incorrect_Answer_Message__c : '');
                }
                
                resultDiv = document.getElementById(curQuesId + "answer-list-div-correct");
                if (resultDiv) {
                    resultDiv.classList.remove("display");
                    resultDiv.classList.add("none");
                }
                
                resultDiv = document.getElementById(curQuesId + "answer-list-div-val-correct");
                if (resultDiv) {
                    resultDiv.classList.remove("display");
                    resultDiv.classList.add("none");
                }
            }

            //Disable Submit button after click submit
            var submitBtn = document.getElementById(quickcheckId + 'submit-btn');
            submitBtn.disabled = true;

            //Disable all question options 
            var quesInput = document.getElementsByClassName(quickcheckId);
            for (var i = 0; i < quesInput.length; i++) {
                quesInput[i].disabled = true;
            }

            var lastQues = document.getElementById(quickcheckId + 'LastQuestion');
            if (lastQues) {
                //Finish
                var finishBtn = document.getElementById(quickcheckId + 'finish-btn');
                if(finishBtn){
                    finishBtn.classList.remove("none");
                    finishBtn.classList.add("display");
                    finishBtn.disabled = false;
                }

                var submitBtn = document.getElementById(quickcheckId + 'submit-btn');
                if(submitBtn){
                    submitBtn.classList.add("none");
                    submitBtn.disabled = true;
                }
                //Disable Next button
                var nextBtn = document.getElementById(quickcheckId + 'next-btn');
                if(nextBtn){
                    nextBtn.classList.add("none");
                    nextBtn.disabled = true;
                }
            } else {
                //Enable Next button
                var nextBtn = document.getElementById(quickcheckId + 'next-btn');
                if(nextBtn){
                    nextBtn.classList.remove("none");
                    nextBtn.disabled = false;
                }
            }
        }
    },
    // Update survey answers upon input
    handleOnClick: function(component, event, helper) {
        //console.log('handleOnClick');
        const questionId = event.target.getAttribute('data-question-id');
        const question = event.target.getAttribute('data-question');

        const userAnswer = {};
        const participantmilestoneId = event.target.getAttribute('data-participantmilestone-id');
        const quickcheckId = event.target.getAttribute('data-quickcheck-id');
        const correctanswers = event.target.getAttribute('data-correctanswers');

        var multiSelect = [];
        console.log(document.getElementById(questionId));
        if (document.getElementById(questionId).classList.contains('multiselect')) {
            var options = document.getElementById(questionId).getElementsByTagName("input");
            console.log('options.length: ' + options.length);
            for (var i = 0; i < options.length; i++) {
                if (options[i].type == "checkbox" && options[i].checked) {
                    console.log(JSON.stringify(options[i]));
                    //first
                    if(i == 0){
                        multiSelect.push(options[i].value);
                    }
                    else{
                        multiSelect.push(' '+options[i].value);
                    }
                }
            }
            userAnswer.Answer = multiSelect;
        } 
        else if(document.getElementById(questionId).classList.contains('datetype')) {
            var dateInput = (event.target.value).split("-");
            userAnswer.Answer = dateInput[1]+'/'+dateInput[2]+'/'+dateInput[0];
            console.log('userAnswer.Answer'+userAnswer.Answer);
        }
        else {
            userAnswer.Answer = event.target.value;
        }
        
        var submitBtn = document.getElementById(quickcheckId + 'submit-btn');
        if (userAnswer.Answer != null && userAnswer.Answer != '') {
            submitBtn.disabled = false;
        } else {
            submitBtn.disabled = true;
        }
        
        console.log('quickcheckId+' + quickcheckId);
        console.log('questionId' + questionId);
        console.log('question' + question);
        console.log('correctanswers' + correctanswers);
        console.log('answer' + userAnswer.Answer);

        userAnswer.QuickCheckId = quickcheckId;
        userAnswer.ParticipantMilestoneId = participantmilestoneId;
        userAnswer.QuestionId = questionId;
        userAnswer.Question = question;
        userAnswer.CorrectAnswers = correctanswers;
        userAnswer.ContactId = component.get("v.contactId");

        //console.log('userAnswer' + JSON.stringify(userAnswer));
        this.result[questionId] = userAnswer;
        //console.log(JSON.stringify(this.result));
    },

    // Verify if all survey questions have been answered
    isSurveyInputValid: function(component, currentTab) {
        console.log('currentTab' + JSON.stringify(currentTab.Id));
        var isValid = true;
        //const bodyElement = document.getElementByClassName(".intake-form");
        var bodyElementVar = "." + (currentTab.Id).replaceAll(' ', '_').replaceAll(',', '_');
        console.log('1');
        var bodyElement = document.querySelector(bodyElementVar);
        console.log('2' + bodyElement);
        var elements = bodyElement.querySelectorAll('input, select, fieldset');
        console.log('3');
        console.log(elements.length + '' + elements);
        for (i = 0; i < elements.length; i++) {
            if (elements[i].hasAttribute('data-question-id')) {
                const questionId = elements[i].getAttribute('data-question-id');
                console.log(questionId);

                if (elements[i].hasAttribute('required') &&
                    (this.result[questionId] === undefined ||
                        this.result[questionId].Answer == '')) {
                    this.toggleErrorMessage(component, questionId, 'on');
                    isValid = false;
                    //console.log('no value');
                } else
                /*if(elements[i].hasAttribute('required') && 
                                  (this.result[questionId] != undefined ||
                                   this.result[questionId].Answer != ''))*/
                {
                    //isValid = true;
                    this.toggleErrorMessage(component, questionId, 'off');
                    //console.log('with value');
                }
            }
        }

        console.log(this.result);
        return isValid;
    },



    //CCN-2291 XenReyes Nov2022
    getUserJourney: function(component, journeyId, helper) {


        let milestoneList = [];
        var userJourney = component.get("c.getUserJourney");
        userJourney.setParams({
            strJourneyId: journeyId
        });

        userJourney.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state ::: ', state);

            var currentDateTime = new Date();

            if (state === "SUCCESS") {
                try {

                    //CCN-2291 XenReyes Nov2022
                    var userJourneyWrapper = helper.cleanUpNamespace(response.getReturnValue());
                    //console.log(userJourneyWrapper);

                    //console.log("!@#userJourneyWrapper.urlFromJourney ::: " + JSON.stringify(userJourneyWrapper.urlFromJourney));
                    if (userJourneyWrapper.urlFromJourney === false) {
                        component.set("v.userJourney", userJourneyWrapper.userJourney);
                        //console.log("!@#userJourney: " + JSON.stringify(userJourneyWrapper.userJourney));
                        component.set("v.urlFromJourney", userJourneyWrapper.urlFromJourney);
                        console.log("!@#userJourneyWrapper.lstUserMilestones ::: " + JSON.stringify(userJourneyWrapper.lstUserMilestones));

                        for (var key of userJourneyWrapper.lstUserMilestones) {
                            console.log('key' + JSON.stringify(key));

                            if (key.Milestone__r.Parent_Milestone__c) {
                                console.log('key');
                                let parentMilestone = milestoneList[key.Milestone__r.Parent_Milestone__c];
                                let childMilestone = parentMilestone.childMilestone ? parentMilestone.childMilestone : [];
                                childMilestone.push(key);
                                parentMilestone.childMilestone = childMilestone;
                            } else {
                                milestoneList[key.Milestone__c] = key;
                                if (key.Milestone__r.Session_Catch_Up_Start_Date__c != undefined && key.Milestone__r.Session_Catch_Up_End_Date__c != undefined) {
                                    let catchupDateStart = new Date(key.Milestone__r.Session_Catch_Up_Start_Date__c);
                                    let catchupDateEnd = new Date(key.Milestone__r.Session_Catch_Up_End_Date__c);

                                    //ADDITIONAL CHECK TO SHOW THE CATCH UP BUTTON
                                    // Updated by Xen [CCN843] March252022
                                    var attendanceCompleted = false;
                                    if (key.Name in (userJourneyWrapper.mapMetricsByMilestoneName)) {
                                        for (let key2 of (userJourneyWrapper.mapMetricsByMilestoneName)[key.Name]) {
                                            if (key2.Metric_Used__c == 'Attendance Date' && (key2.Completion_Date__c == null || key2.Completion_Date__c == undefined)) attendanceCompleted = true;
                                        }
                                    }
                                    // Updated by Xen [CCN843] March252022

                                    key.Milestone__r.isCatchupAvailable = key.Milestone__r.Catch_Up_Completion_Button__c && this.computeForSessionCatchUp(component, catchupDateStart, catchupDateEnd, currentDateTime) && attendanceCompleted;
                                }
                            }

                        }
                        console.log('milestoneList');
                        component.set("v.contactId", userJourneyWrapper.contactId);

                        let mapCtr = new Map();
                        for (var key of userJourneyWrapper.lstQuickCheckAnswer) {
                            if (mapCtr.has(key.QuickCheckId__c)) {
                                mapCtr.set(key.QuickCheckId__c, mapCtr.get(key.QuickCheckId__c) + 1);
                                key.counter = mapCtr.get(key.QuickCheckId__c);
                            } else {
                                mapCtr.set(key.QuickCheckId__c, 1);
                                key.counter = 1;
                            }
                        }

                        console.log("!@#userJourneyWrapper.lstQuickCheckAnswer ::: " + JSON.stringify(Object.values(userJourneyWrapper.lstQuickCheckAnswer)));
                        component.set(
                            "v.finalResultVal",
                            Object.values(userJourneyWrapper.lstQuickCheckAnswer) //Object.values(milestoneList)
                        );

                        if (userJourneyWrapper.lstUserMilestones !== undefined) {
                            component.set(
                                "v.userMilestones",
                                Object.values(milestoneList)
                            );
                            console.log("!@#userJourneyWrapper.mapTasksByMilestoneName ::: " + JSON.stringify(userJourneyWrapper.userJourneyWrapper));
                            if (userJourneyWrapper.mapTasksByMilestoneName !== undefined) {
                                var acts = [];
                                for (var key in userJourneyWrapper.mapTasksByMilestoneName) {
                                    acts.push({
                                        value: userJourneyWrapper.mapTasksByMilestoneName[key],
                                        key: key
                                    });
                                    console.log("!@# Milestone: " + key);
                                }
                                console.log('acts ::: ', acts);
                                component.set("v.userMilestoneRelatedInfo", acts);
                            }
                            //mel
                            console.log("!@#userJourneyWrapper.quickCheckQuestions ::: " + JSON.stringify(userJourneyWrapper.quickCheckQuestions));


                            if (userJourneyWrapper.quickCheckQuestions !== undefined) {
                                var qcq = [];
                                for (var key in userJourneyWrapper.quickCheckQuestions) {
                                    for (var i = 0; i < userJourneyWrapper.quickCheckQuestions[key].length; i++) {
                                        var row = userJourneyWrapper.quickCheckQuestions[key][i];
                                        row.counter = i + 1;
                                        row.options = row.Answers__c != undefined ? row.Answers__c.split(/\r?\n/) : [];
                                    }
                                    console.log("!@# Milestone: " + key);
                                    qcq.push({
                                        value: userJourneyWrapper.quickCheckQuestions[key],
                                        key: key
                                    });
                                }
                                console.log('qcq ::: ', qcq);
                                component.set("v.quickCheckQuestions", qcq);
                            }
                            //mel
                        }
                    } else if (userJourneyWrapper.urlFromJourney === true) {
                        component.set(
                            "v.journeyMilestoneList",
                            userJourneyWrapper.lstUserMilestones
                        );
                        console.log("!@#userJourneyWrapper.journeyData ::: " + JSON.stringify(userJourneyWrapper.journeyData));
                        component.set("v.journeyData", userJourneyWrapper.journeyData);
                    }
                } catch (error) {
                    console.error(error);
                }
            } else {
                console.log("!@# User Journey not found!");
            }
        });
        $A.enqueueAction(userJourney);
    },

    updateParticipantMilestoneMetric: function(component, event, helper) {
        var updateParticipantMilestoneMetric = component.get("c.processSurveyAssessmentComplete");
        const milestoneId = event.getSource().get("v.name");
        updateParticipantMilestoneMetric.setParams({
            participantMilestoneId: milestoneId
        });

        updateParticipantMilestoneMetric.setCallback(this, function(response) {
            const state = response.getState();
            console.log('!@#$ J_STATE: ' + state);
            console.log('!@#$ J_RESPONSE: ' + JSON.stringify(response.getReturnValue()));
            if (state === "SUCCESS") {
                component.set("v.spinner", false);
                const hasErrors = response.getReturnValue();

                let message = '';

                let type = "Success";
                if (!hasErrors) {
                    let userMilestone = component.get("v.userMilestones");
                    for (let i = 0; i < userMilestone.length; i++) {
                        if (userMilestone[i].Id === milestoneId) {
                            userMilestone[i].Progress__c = 100;

                            if (userMilestone[i].Type__c.includes('Attestation')) {
                                message = "Thank you for completing the attestation!";
                            } else {
                                message = "We have received your response. Thank you!";
                            }
                        }
                    }
                    window.location.reload();
                    component.set("v.userMilestones", userMilestone);
                } else {
                    message = "Something went wrong. Please try again later."
                    type = "Error";
                }

                var resultToast = $A.get("e.force:showToast");
                resultToast.setParams({
                    message: message,
                    type: type
                });
                resultToast.fire();
            }
        });

        $A.enqueueAction(updateParticipantMilestoneMetric);
    },

    updateParticipantEventMetric: function(component, event, helper) {
        var updateParticipantEventMetric = component.get("c.processEventCatchUp");
        const milestoneId = event.getSource().get("v.name");
        console.log("handleEventCatchUp");
        console.log(milestoneId);
        updateParticipantEventMetric.setParams({
            participantMilestoneId: milestoneId
        });

        updateParticipantEventMetric.setCallback(this, function(response) {
            const state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                component.set("v.spinner", false);
                const hasErrors = response.getReturnValue();
                let message = "Thank you for completing the Catch-Up steps!";
                let type = "Success";
                if (!hasErrors) {
                    let userMilestone = component.get("v.userMilestones");
                    for (let i = 0; i < userMilestone.length; i++) {
                        if (userMilestone[i].Id === milestoneId) {
                            userMilestone[i].Progress__c = 100;
                        }
                    }
                    //window.location.reload();
                    component.set("v.userMilestones", userMilestone);
                } else {
                    message = "Something went wrong. Please try again later."
                    type = "Error";
                }

                var resultToast = $A.get("e.force:showToast");
                resultToast.setParams({
                    message: message,
                    type: type
                });
                resultToast.fire();
            } else if (state === "ERROR") {
                console.log(state);
                let errors = response.getError();
                console.log(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                    // Updated by RiannoRizarri [CCN843] March252022
                    var resultToast = $A.get("e.force:showToast");
                    resultToast.setParams({
                        message: errors[0].message,
                        type: "Error"
                    });
                    resultToast.fire();
                    // Updated by RiannoRizarri [CCN843] March252022
                }
            }
        });

        $A.enqueueAction(updateParticipantEventMetric);
    },

    computeForSessionCatchUp: function(component, startDateTime, endDateTime, currentDateTime) {
        let isCatchupAvailable = false;

        startDateTime.setMinutes(startDateTime.getMinutes() - 15);
        endDateTime.setMinutes(endDateTime.getMinutes() + 30);

        if (currentDateTime >= startDateTime && currentDateTime <= endDateTime) {
            isCatchupAvailable = true;
        }

        return isCatchupAvailable;
    },

    cleanUpNamespace: function(jsonData) {
        let responseStr = JSON.stringify(jsonData);

        if (responseStr.includes('beta_ccn__')) {
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if (responseStr.includes('compass_cn__')) {
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }

        return JSON.parse(responseStr);
    }

});