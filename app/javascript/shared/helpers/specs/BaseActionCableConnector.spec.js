import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import BaseActionCableConnector from '../BaseActionCableConnector';

const consumers = [];

vi.mock('@rails/actioncable', () => ({
  createConsumer: vi.fn(() => {
    const socketEventHandlers = {};
    const subscription = {
      unsubscribe: vi.fn(),
      updatePresence: vi.fn(),
    };
    const consumer = {
      connection: {
        isOpen: vi.fn(() => true),
        webSocket: {
          addEventListener: vi.fn((event, callback) => {
            socketEventHandlers[event] = callback;
          }),
        },
      },
      disconnect: vi.fn(),
      subscriptions: {
        create: vi.fn((_, callbacks) => {
          subscription.callbacks = callbacks;
          return subscription;
        }),
      },
    };
    consumers.push({ consumer, subscription, socketEventHandlers });
    return consumer;
  }),
}));

class TestConnector extends BaseActionCableConnector {
  disconnectedCount = 0;

  reconnectedCount = 0;

  onDisconnected = () => {
    this.disconnectedCount += 1;
  };

  onReconnect = () => {
    this.reconnectedCount += 1;
  };
}

const app = {
  $store: {
    getters: {
      getCurrentAccountId: 1,
      getCurrentUserID: 2,
    },
  },
};

describe('BaseActionCableConnector', () => {
  let connector;

  beforeEach(() => {
    consumers.length = 0;
    vi.useFakeTimers();
    vi.spyOn(Math, 'random').mockReturnValue(0.5);
    Object.defineProperty(navigator, 'onLine', { configurable: true, value: true });
    connector = new TestConnector(app, 'token', '', 20000, 30000, 90000);
  });

  afterEach(() => {
    connector?.disconnect();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('replaces the consumer and reconciles only after a fresh subscription confirms', () => {
    consumers[0].subscription.callbacks.connected();
    consumers[0].subscription.callbacks.disconnected();

    expect(connector.disconnectedCount).toBe(1);
    vi.advanceTimersByTime(1000);

    expect(consumers).toHaveLength(2);
    expect(consumers[0].subscription.unsubscribe).toHaveBeenCalledOnce();
    expect(consumers[0].consumer.disconnect).toHaveBeenCalledOnce();
    expect(connector.reconnectedCount).toBe(0);

    consumers[1].subscription.callbacks.connected();

    expect(connector.reconnectedCount).toBe(1);
    expect(connector.subscription).toBe(consumers[1].subscription);
  });

  it('replaces an open but stale connection instead of trusting isOpen', () => {
    consumers[0].subscription.callbacks.connected();
    connector.lastActivityAt = Date.now() - 90001;

    connector.checkConnectionHealth();
    vi.advanceTimersByTime(1000);

    expect(consumers).toHaveLength(2);
    expect(connector.disconnectedCount).toBe(1);
  });

  it('does not create parallel reconnect attempts', () => {
    consumers[0].subscription.callbacks.connected();
    consumers[0].subscription.callbacks.disconnected();
    consumers[0].subscription.callbacks.rejected();
    connector.checkConnectionHealth();

    vi.advanceTimersByTime(1000);

    expect(consumers).toHaveLength(2);
    expect(connector.disconnectedCount).toBe(1);
  });

  it('ignores delayed lifecycle callbacks from a replaced connection', () => {
    consumers[0].subscription.callbacks.connected();
    consumers[0].subscription.callbacks.disconnected();
    vi.advanceTimersByTime(1000);

    consumers[1].subscription.callbacks.connected();
    expect(connector.reconnectedCount).toBe(1);

    consumers[0].subscription.callbacks.disconnected();
    consumers[0].subscription.callbacks.rejected();
    consumers[0].socketEventHandlers.close();
    consumers[0].socketEventHandlers.error();
    connector.handleUnhealthyConnection('subscription_timeout', 1);
    connector.checkConnectionHealth(1);
    vi.advanceTimersByTime(30000);

    expect(consumers).toHaveLength(2);
    expect(connector.consumer).toBe(consumers[1].consumer);
    expect(connector.subscription).toBe(consumers[1].subscription);
    expect(connector.disconnectedCount).toBe(1);
    expect(connector.reconnectedCount).toBe(1);
  });

  it('stops timers and does not reconnect after explicit teardown', () => {
    connector.disconnect();
    consumers[0].subscription.callbacks.disconnected();
    vi.advanceTimersByTime(30000);

    expect(consumers).toHaveLength(1);
    expect(consumers[0].subscription.unsubscribe).toHaveBeenCalledOnce();
  });
});
