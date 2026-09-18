# WhatsApp credential encryption recovery

`Channel::Whatsapp` keeps non-secret routing fields in `provider_config` and stores WABA access tokens, app secrets, webhook verification tokens, and registration PINs in `encrypted_provider_config`. The latter is protected with Rails Active Record encryption keys supplied through the three `ACTIVE_RECORD_ENCRYPTION_*` environment variables.

## Initial migration

1. Back up PostgreSQL and verify a restore before changing application data.
2. Put all three encryption values in Coolify secrets. They must be high-entropy values generated and retained in the password manager; never commit them or place them in an image.
3. Deploy the migration, then run `bundle exec rails volitex:encrypt_whatsapp_provider_configs` once from the release environment.
4. Confirm `channel_whatsapp.provider_config` no longer contains any of the sensitive keys in a database-only inspection, and test inbound and outbound WhatsApp traffic.

## Key loss or replacement

There is no safe decryption fallback. If the encryption keys are lost, restore the keys from the password manager or restore a database backup together with the key set that encrypted it. If neither exists, the affected WABA channels must be re-authorized with new credentials and webhook verification tokens.

Never rotate or delete a key until every encrypted database backup that depends on it has either expired under the retention policy or is retained with an escrowed copy of that key. Test a staged restore after any planned key change.
