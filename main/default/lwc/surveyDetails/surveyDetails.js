import { LightningElement, api, track } from 'lwc';
import getSurvey from '@salesforce/apex/CCESurveyController.getSurvey';

/* Updated by Xen Reyes CCN-822 Nov012021 */
import getEventDetails from '@salesforce/apex/CCESurveyController.getEventDetails';

import getSurveyFieldConfiguration from '@salesforce/apex/CCESurveyController.getSurveyFieldConfiguration';
import getParticipantDetails from '@salesforce/apex/CCESurveyController.getParticipantDetails';
import createResponse from '@salesforce/apex/CCESurveyController.createResponse';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CCE_LOGO from '@salesforce/resourceUrl/Change_Cloud_Events_Logo';
import FOOTER_LOGO from '@salesforce/resourceUrl/communityEventFooterLogo';
import COMMUNITY_EVENT_UI from '@salesforce/resourceUrl/community_event_ui';
import SURVEY_UI from '@salesforce/resourceUrl/customIndependentSurvey';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class SurveyDetails extends LightningElement {
    eventId;
    participantNumber;
    participantEmail; //compare email with the one on the participant to avoid answering someone else's survey
    hasParticipantDetails = false;
    surveyName;
    surveyDescription;
    showButton = false;
    surveyQuestionResponses = {};
    showSpinner = false;
    @track formFields = {};
    CCE_LOGO = CCE_LOGO;
    surveyLogoString = '';
    disclaimerText;
    spinnerHeight;
    FOOTER_LOGO = FOOTER_LOGO;
    showNoEventSurveyMessage = false;
    showNoSurveyMessage = false;
    showSurveyLogo = false;
    isIndependentSurvey = false;
    isRendered = false;
    @track elementAttributes = [];
    @track surveyFieldsLeftColumn = [];
    @track surveyFieldsRightColumn = [];
    @track surveyQuestionValidity = {};
    hasFieldsInRight = false;

    /* CCN-EVE-2074-DV XEN REYES Oct2022 */
    hasRequiredField = false;

    constructor() {
        super();
        const url = new URL(window.location.href);
        this.eventId = url.searchParams.get('id');
        this.participantNumber = url.searchParams.get('pm');
        this.participantEmail = url.searchParams.get('email');
    }

    connectedCallback() {
        this.showSpinner = true;

        getSurvey({
            eventId: this.eventId
        })
        .then((rs) => {
            if (rs != null) {
                let result = JSON.parse(rs);
                this.surveyName = result.Survey.Name;
                /* Updated [EVENT REFRESH FIXES] JaysonLabnao Feb022022 - As per Shawn description and disclaimer should be in Calibri */
                if(result.Survey.Disclaimer){
                    this.disclaimerText = result.Survey.Disclaimer.replaceAll('font-family:', 'text-justify: none; font-family: Calibri, ');
                }
                if(result.Survey.Description){
                    this.surveyDescription = result.Survey.Description.replaceAll('font-family:', 'text-justify: none; font-family: Calibri, ');
                }

                if (result.BlobWrapper){
                    this.showSurveyLogo = true;
                    this.surveyLogoString = "data:image/" + result.BlobWrapper.FileType + ";base64, " + result.BlobWrapper.VersionData;
                }

                let questions = result.Survey.SurveyQuestionList;
                
                for (let i = 0; i < questions.length; i++) {                        
                    let elementAttr = {};
                    elementAttr.questionId = questions[i].Id;
                    elementAttr.label = questions[i].Description;
                    elementAttr.type = questions[i].QuestionType;
                    elementAttr.options =
                        questions[i].Options != undefined
                            ? questions[i].Options.split(/\r?\n/)
                            : [];
                    elementAttr.max =
                        questions[i].MaxValue != undefined
                            ? questions[i].MaxValue
                            : 0;
                    elementAttr.min =
                        questions[i].MinValue != undefined
                            ? questions[i].MinValue
                            : 0;
                    elementAttr.step =
                        questions[i].Step != undefined
                            ? questions[i].Step
                            : 1;
                    
                    /* Updated by Xen Reyes CCN-822 Nov012021 */
                    elementAttr.isRequired = questions[i].isRequired;
                    elementAttr.questionTitle = 'Question ' + (i + 1);

                    this.elementAttributes.push(elementAttr);
                }

                this.showButton = true;
                this.showSpinner = false;
                this.error = undefined;
            } else {
                setTimeout(() => {
                    this.template.querySelector('.survey').style.display =
                        'none';
                    
                    if (this.isIndependentSurvey){
                        this.showNoSurveyMessage = true;
                    } else {
                        this.showNoEventSurveyMessage = true;
                    }

                    this.showSpinner = false;
                    
                }, 1000);
            }
        })
        .catch((error) => {
            console.log(error);
            this.showNotification(
                'Oops!',
                "Something's not right. Please contact the administrator for help.",
                'error',
                'pester'
            );
        });

        getSurveyFieldConfiguration({
            code: this.eventId
        })
        .then((response) => {
            if (response != null && response.length > 0) {
                let results = JSON.parse(response);
                let hasNoLeftFields = true;

                for (let i = 0 ; i < results.length ; i++){
                    let field = results[i];
                    const STYLE = 'slds-col slds-size_1-of-1 slds-large-size_1-of-2 slds-order_' + i;

                    if (field.column === "Left" || FORM_FACTOR === "Small"){
                        hasNoLeftFields = false;
                        this.surveyFieldsLeftColumn.push({Field : field, IsPicklist : field.fieldType === "Picklist", Value : "", Style: STYLE});
                    } else {
                        this.surveyFieldsRightColumn.push({Field : field, IsPicklist : field.fieldType === "Picklist", Value : "", Style: STYLE});
                        this.hasFieldsInRight = true;
                    }

                    /* CCN-EVE-2074-DV XEN REYES Oct2022 */
                    if(!this.hasRequiredField && field.isRequired){
                        this.hasRequiredField = true;
                    }
                }

                if (hasNoLeftFields) {
                    this.surveyFieldsLeftColumn = JSON.parse(JSON.stringify(this.surveyFieldsRightColumn));
                    this.surveyFieldsRightColumn = [];
                    this.hasFieldsInRight = false;
                }

                this.getDefaultValuesForSurveyFields();
            }
        })
        .catch((error) => {
            console.log(error);
            this.showNotification(
                'Oops!',
                "There was an error encountered while fetching survey form fields.",
                'error',
                'pester'
            );
        });

        /* Updated by Xen Reyes CCN-822 Nov012021 */
        getEventDetails({
            eventId: this.eventId
        })
        .then((response) => {
            if (response != null || response !=  undefined) {
                this.surveyPageTitle = response;
            }
            else{
                this.surveyPageTitle = 'SURVEY';
            }
        })
        .catch((error) => {
            console.log('errpr'+error);
            this.showNotification(
                'Oops!',
                "There was an error encountered while fetching Event Detail.",
                'error',
                'pester'
            );
        });



    }

    getDefaultValuesForSurveyFields(){
        getParticipantDetails({
            participantNumber : this.participantNumber,
            participantEmail : this.participantEmail,
            isStandalone : false
        })
        .then((response) => {
            if (response != null) {
                this.hasParticipantDetails = true;
                let surveyFields = this.surveyFieldsLeftColumn.concat(this.surveyFieldsRightColumn);
                for (let i = 0 ; i < surveyFields.length ; i++){
                    let field = surveyFields[i];
                    
                    if (field.Field.apiName === 'FirstName'){
                        field.Value = response.FirstName;
                    } else if (field.Field.apiName === 'LastName') {
                        field.Value = response.LastName;
                    } else if (field.Field.apiName === 'Email') {
                        field.Value = response.Email;
                    } else if (field.Field.apiName === 'Facility__c') {
                        field.Value = response.Facility__c;
                    }

                    this.formFields[field.Field.key] = field.Value;
                }
            }
        })
        .catch((error) => {
            console.log(error);
            this.showNotification(
                'Oops!',
                "There was an error encountered while fetching participant details.",
                'error',
                'pester'
            );
        });
    }

    renderedCallback(){
        if (!this.isRendered){
            loadStyle(this, COMMUNITY_EVENT_UI + '/cc-ui-min.css');
            loadStyle(this, COMMUNITY_EVENT_UI + '/cc-ui-font-min.css');
            loadStyle(this, SURVEY_UI);

            this.isRendered = true;
        }
    }

    // Update user details upon input
    handleChange(event) {

        //XEN REYES CCN-SUR-3235-DV 14 July 2023
        var value = event.target.value;
        if(event.target.type == 'date' && value){
            let objectDate = new Date(value);
            let formattedDate = `${objectDate.getMonth() + 1}/${objectDate.getDate()}/${objectDate.getFullYear()}`;
            value = formattedDate;
        }
        this.formFields[event.target.name] = value
    }

    // Update survey answers upon input
    handleOnClick(event) {
        const IS_VALID = event.detail.isValid;
        let eventObj = event.detail.eventObj;

        const name = eventObj.target.name;

        //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022
        var value = eventObj.target.value;
        if(typeof value == 'object'){
            value = JSON.stringify(value);
        }

        //Xen Reyes CCN-SUR-3092-DV 8 June 2023
        if(eventObj.target.type == 'date' && value){
            let objectDate = new Date(value);
            let formattedDate = `${objectDate.getMonth() + 1}/${objectDate.getDate()}/${objectDate.getFullYear()}`;
            value = formattedDate;
        }
        
        const questionId = eventObj.target.getAttribute('data-question-id');
        const userAnswer = {Question : name, Answer : value};
        
        this.surveyQuestionResponses[questionId] = userAnswer;

        this.surveyQuestionValidity[questionId] = IS_VALID;
    }

    handleSubmit() {
        
        /* CCN-EVE-2074-DV XEN REYES Oct2022 */
        let isContactDetailsValid = false;
        let isSurveyInputValid = false;

        if(this.isContactDetailsValid()) isContactDetailsValid = true;
        if(this.isSurveyInputValid()) isSurveyInputValid = true;

        if (isContactDetailsValid && isSurveyInputValid) {
            this.disableButton();

            createResponse({
                eventId: this.eventId,
                formDetailAnswers: JSON.stringify(this.formFields),
                surveyQuestionAnswers: JSON.stringify(this.surveyQuestionResponses),
                participantNumber: this.hasParticipantDetails ? this.participantNumber : '',
                isStandalone: false
            })
            .then((result) => {
                this.showNotification(
                    'Success!',
                    'Your response has been submitted.',
                    'success',
                    'pester'
                );
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                if (error)
                    this.showNotification(
                        'Oops!',
                        "Something's not right. Please contact the administrator for help.",
                        'error',
                        'pester'
                    );
            });
        }
    }

    // Toast message method
    showNotification(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(evt);
    }

    // Verify if required contact details have been correctly filled in
    isContactDetailsValid() {
        const allValid = [
            ...this.template.querySelectorAll('.form-fields'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        return allValid;
    }

    // Verify if all survey questions have been answered
    isSurveyInputValid() {
        var isValid = true;

        for (var i = 0 ; i < this.elementAttributes.length ; i++){
            let element = this.elementAttributes[i];

            //if fields weren't changed
            if (this.surveyQuestionValidity[element.questionId] === undefined || !this.surveyQuestionValidity[element.questionId]){
                
                /* Updated by Xen Reyes CCN-822 Nov012021 */
                //set the default value of the field if it's range
                /* if (element.type === "Range"){
                    this.surveyQuestionResponses[element.questionId] = {Question : element.label, Answer : element.min};
                } else */
                
                if (element.isRequired){
                    isValid = false;
                
                    this.template.querySelectorAll('c-survey-detail-element').forEach(surveyElement => {
                        surveyElement.toggleErrorMessage(element.questionId, true);
                    });
                } else {
                    //set default value so the question can still be saved without any answer
                    this.surveyQuestionResponses[element.questionId] = {Question : element.label, Answer : ''};
                }
            } else {
                this.template.querySelectorAll('c-survey-detail-element').forEach(surveyElement => {
                    surveyElement.toggleErrorMessage(element.questionId, false);
                });
            }
        }
        
        return isValid;
    }

    // Check if email is valid
    isEmailValid(email) {
        let isEmailValid = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(
            email
        );
        return isEmailValid;
    }

    // Disable button
    disableButton() {
        this.showSpinner = true;

        /* Updated by Xen Reyes CCN-822 Nov012021 */
        const button = this.template.querySelector('.btn-base-parking');
        
        button.classList.add('disabled');
    }
}