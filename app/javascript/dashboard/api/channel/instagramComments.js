/* global axios */
import ApiClient from '../ApiClient';

class InstagramComments extends ApiClient {
  constructor() {
    super('instagram/comments', { accountScoped: true });
  }

  media(inboxId, after) {
    return axios.get(`${this.url}/media`, { params: { inbox_id: inboxId, after } });
  }

  list(inboxId, mediaId, after) {
    return axios.get(this.url, { params: { inbox_id: inboxId, media_id: mediaId, after } });
  }

  create(inboxId, mediaId, message) {
    return axios.post(this.url, { inbox_id: inboxId, media_id: mediaId, message });
  }

  reply(inboxId, commentId, message) {
    return axios.post(`${this.url}/${commentId}/reply`, { inbox_id: inboxId, message });
  }

  setVisibility(inboxId, commentId, hide) {
    return axios.patch(`${this.url}/${commentId}`, { inbox_id: inboxId, hide });
  }

  delete(inboxId, commentId) {
    return axios.delete(`${this.url}/${commentId}`, { params: { inbox_id: inboxId } });
  }
}

export default new InstagramComments();
