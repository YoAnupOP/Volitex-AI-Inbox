/* global axios */

import ApiClient from './ApiClient';

class QuickMenu extends ApiClient {
  constructor() {
    super('quick_menus', { accountScoped: true });
  }

  send(conversationId, quickMenuId) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/send_quick_menu`,
      { quick_menu_id: quickMenuId }
    );
  }
}

export default new QuickMenu();
