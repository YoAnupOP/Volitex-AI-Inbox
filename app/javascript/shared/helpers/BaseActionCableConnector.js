import { createConsumer } from '@rails/actioncable';

const PRESENCE_INTERVAL = 20000;
const HEALTH_CHECK_INTERVAL = 30000;
const STALE_CONNECTION_THRESHOLD = 90000;
const SUBSCRIPTION_TIMEOUT = 10000;
const RECONNECT_BASE_DELAY = 1000;
const RECONNECT_MAX_DELAY = 30000;

class BaseActionCableConnector {
  constructor(
    app,
    pubsubToken,
    websocketHost = '',
    presenceInterval = PRESENCE_INTERVAL,
    healthCheckInterval = HEALTH_CHECK_INTERVAL,
    staleConnectionThreshold = STALE_CONNECTION_THRESHOLD
  ) {
    this.app = app;
    this.pubsubToken = pubsubToken;
    this.websocketURL = websocketHost ? `${websocketHost}/cable` : undefined;
    this.presenceInterval = presenceInterval;
    this.healthCheckInterval = healthCheckInterval;
    this.staleConnectionThreshold = staleConnectionThreshold;
    this.events = {};
    this.isAValidEvent = () => true;
    this.reconnectTimer = null;
    this.presenceTimer = null;
    this.healthCheckTimer = null;
    this.subscriptionTimeoutTimer = null;
    this.reconnectAttempts = 0;
    this.connectionGeneration = 0;
    this.subscriptionConfirmed = false;
    this.recovering = false;
    this.stopped = false;
    this.lastActivityAt = Date.now();
    this.observedWebSocket = null;

    this.createConnection();
    this.startPresenceUpdates();
    this.startHealthChecks();
    this.addBrowserEventListeners();
  }

  createConnection = () => {
    const generation = ++this.connectionGeneration;
    this.subscriptionConfirmed = false;
    this.consumer = createConsumer(this.websocketURL);
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        pubsub_token: this.pubsubToken,
        account_id: this.app.$store.getters.getCurrentAccountId,
        user_id: this.app.$store.getters.getCurrentUserID,
      },
      {
        connected: () => this.handleSubscriptionConnected(generation),
        disconnected: () =>
          this.handleUnhealthyConnection(
            'subscription_disconnected',
            generation
          ),
        rejected: () =>
          this.handleUnhealthyConnection('subscription_rejected', generation),
        received: payload => this.handleReceived(payload, generation),
        updatePresence() {
          this.perform('update_presence');
        },
      }
    );

    this.subscriptionTimeoutTimer = setTimeout(() => {
      if (generation === this.connectionGeneration && !this.subscriptionConfirmed) {
        this.handleUnhealthyConnection('subscription_timeout', generation);
      }
    }, SUBSCRIPTION_TIMEOUT);

    setTimeout(() => this.observeWebSocket(generation), 0);
  };

  handleSubscriptionConnected = generation => {
    if (generation !== this.connectionGeneration || this.stopped) return;

    this.clearSubscriptionTimeout();
    this.subscriptionConfirmed = true;
    this.lastActivityAt = Date.now();
    this.reconnectAttempts = 0;
    this.clearReconnectTimer();
    this.observeWebSocket(generation);

    if (this.recovering) {
      this.recovering = false;
      this.logDiagnostic('reconnect_success');
      this.onReconnect();
    }
  };

  handleReceived = (payload, generation) => {
    if (generation !== this.connectionGeneration || this.stopped) return;

    this.lastActivityAt = Date.now();
    this.onReceived(payload);
  };

  handleUnhealthyConnection = (
    reason,
    generation = this.connectionGeneration
  ) => {
    if (generation !== this.connectionGeneration || this.stopped) return;

    if (!this.recovering) {
      this.recovering = true;
      this.subscriptionConfirmed = false;
      this.logDiagnostic('reconnect_required', { reason });
      this.onDisconnected();
      this.disconnectCurrentConnection();
    }

    this.scheduleReconnect();
  };

  scheduleReconnect = () => {
    if (this.reconnectTimer || this.stopped || !navigator.onLine) return;

    const exponentialDelay = Math.min(
      RECONNECT_BASE_DELAY * 2 ** this.reconnectAttempts,
      RECONNECT_MAX_DELAY
    );
    const delay = Math.round(exponentialDelay * (0.75 + Math.random() * 0.5));
    this.reconnectAttempts += 1;
    this.logDiagnostic('reconnect_attempt', { attempt: this.reconnectAttempts, delay });

    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.replaceConnection();
    }, delay);
  };

  replaceConnection = () => {
    if (this.stopped || this.subscriptionConfirmed) return;

    this.disconnectCurrentConnection();
    this.createConnection();
  };

  checkConnectionHealth = (generation = this.connectionGeneration) => {
    if (
      generation !== this.connectionGeneration ||
      this.stopped ||
      !navigator.onLine ||
      document.hidden
    ) {
      return;
    }

    const isOpen = this.consumer?.connection?.isOpen?.();
    const stale =
      Date.now() - this.lastActivityAt > this.staleConnectionThreshold;
    if (!this.subscriptionConfirmed || !isOpen || stale) {
      this.handleUnhealthyConnection(
        stale ? 'stale_connection' : 'connection_unhealthy',
        generation
      );
    }
  };

  observeWebSocket = generation => {
    if (generation !== this.connectionGeneration) return;

    const webSocket = this.consumer?.connection?.webSocket;
    if (!webSocket || webSocket === this.observedWebSocket) return;

    this.observedWebSocket = webSocket;
    webSocket.addEventListener('close', () =>
      this.handleUnhealthyConnection('websocket_close', generation)
    );
    webSocket.addEventListener('error', () =>
      this.handleUnhealthyConnection('websocket_error', generation)
    );
  };

  startPresenceUpdates = () => {
    this.presenceTimer = setInterval(() => {
      if (this.subscriptionConfirmed) this.subscription.updatePresence();
    }, this.presenceInterval);
  };

  startHealthChecks = () => {
    this.healthCheckTimer = setInterval(
      this.checkConnectionHealth,
      this.healthCheckInterval
    );
  };

  addBrowserEventListeners = () => {
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);
    document.addEventListener('visibilitychange', this.handleVisibilityChange);
  };

  removeBrowserEventListeners = () => {
    window.removeEventListener('online', this.handleOnline);
    window.removeEventListener('offline', this.handleOffline);
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
  };

  handleOnline = () => {
    const generation = this.connectionGeneration;
    this.lastActivityAt = 0;
    this.checkConnectionHealth(generation);
  };

  handleOffline = () =>
    this.handleUnhealthyConnection('browser_offline', this.connectionGeneration);

  handleVisibilityChange = () => {
    if (!document.hidden) this.checkConnectionHealth(this.connectionGeneration);
  };

  clearReconnectTimer = () => {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
  };

  clearSubscriptionTimeout = () => {
    if (this.subscriptionTimeoutTimer) {
      clearTimeout(this.subscriptionTimeoutTimer);
      this.subscriptionTimeoutTimer = null;
    }
  };

  disconnectCurrentConnection = () => {
    this.clearSubscriptionTimeout();
    this.subscription?.unsubscribe();
    this.consumer?.disconnect();
  };

  logDiagnostic = (event, details = {}) => {
    // Deliberately excludes pubsub tokens, websocket URLs, and event payloads.
    if (window.chatwootConfig?.logActionCableDiagnostics) {
      // eslint-disable-next-line no-console
      console.info('[ActionCable]', { event, ...details });
    }
  };

  // eslint-disable-next-line class-methods-use-this
  onReconnect = () => {};

  // eslint-disable-next-line class-methods-use-this
  onDisconnected = () => {};

  disconnect() {
    this.stopped = true;
    this.clearReconnectTimer();
    this.clearSubscriptionTimeout();
    clearInterval(this.presenceTimer);
    clearInterval(this.healthCheckTimer);
    this.removeBrowserEventListeners();
    this.disconnectCurrentConnection();
  }

  onReceived = ({ event, data } = {}) => {
    if (
      this.isAValidEvent(data) &&
      this.events[event] &&
      typeof this.events[event] === 'function'
    ) {
      this.events[event](data);
    }
  };
}

export default BaseActionCableConnector;
