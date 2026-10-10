import { frontendURL } from '../../../../helper/URLHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import SettingsWrapper from '../SettingsWrapper.vue';
import QuickMenuSettings from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/quick-menus'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'quick_menus',
          meta: { permissions: [...ROLES, ...CONVERSATION_PERMISSIONS] },
          component: QuickMenuSettings,
        },
      ],
    },
  ],
};
