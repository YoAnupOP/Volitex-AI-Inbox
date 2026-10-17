/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  control(id, action) {
    return axios.post(`${this.url}/${id}/${action}`);
  }

  recipients(id, afterId = 0) {
    return axios.get(`${this.url}/${id}/recipients`, {
      params: { after_id: afterId },
    });
  }

  constructor() {
    super('campaigns', { accountScoped: true });
  }
}

export default new CampaignsAPI();
