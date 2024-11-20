/* eslint-disable no-console */
import { LightningElement, wire, track, api} from 'lwc';
import getAllVideos from '@salesforce/apex/VideoListController.getAllVideos';

export default class Videos extends LightningElement {
    @api flexipageRegionWidth;
    @api recordId;
    @api communityUrl;
    @api videoWidth;
    @api videoHeight;
    @track videoResult = [];
    @track noVideos = false;
    
    @wire (getAllVideos,{recordId:'$recordId', communityUrl : '$communityUrl'})
    videos(result){
        if(result && result.data && result.data.result){
            this.videoResult = result.data.result;
            if(Array.isArray(this.videoResult) && this.videoResult.length <= 0){
                this.noVideos = true;
            }
        }
    }

    connectedCallback() {
        //console.log(this.recordId);
        //console.log(this.communityUrl);
        if(this.communityUrl == undefined){
            this.communityUrl = '';
            this.isCommunityPage = true;
        }
    }
}