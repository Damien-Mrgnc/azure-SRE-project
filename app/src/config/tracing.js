/**
 * OpenTelemetry Tracing Setup
 *
 * IMPORTANT: This file MUST be required before any other import in server.js
 * (before express, prisma, etc.) so the OTel SDK can auto-instrument them.
 *
 * Exports traces to Azure Application Insights via the Azure Monitor exporter.
 * The APPLICATIONINSIGHTS_CONNECTION_STRING env var is automatically injected
 * by Azure when Application Insights is linked to the App Service.
 */

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { AzureMonitorTraceExporter } = require('@azure/monitor-opentelemetry-exporter');
const { Resource } = require('@opentelemetry/resources');
const { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } = require('@opentelemetry/semantic-conventions');

const exporter = new AzureMonitorTraceExporter({
    // Falls back to APPLICATIONINSIGHTS_CONNECTION_STRING env var automatically
    connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
});

const sdk = new NodeSDK({
    resource: new Resource({
        [ATTR_SERVICE_NAME]: 'runtime-governance-app',
        [ATTR_SERVICE_VERSION]: '1.0.0',
    }),
    traceExporter: exporter,
    instrumentations: [
        getNodeAutoInstrumentations({
            // Auto-instrument HTTP, Express, Prisma, Redis
            '@opentelemetry/instrumentation-http': { enabled: true },
            '@opentelemetry/instrumentation-express': { enabled: true },
            '@opentelemetry/instrumentation-redis': { enabled: true },
            // Disable noisy fs instrumentation
            '@opentelemetry/instrumentation-fs': { enabled: false },
        }),
    ],
});

sdk.start();

// Graceful shutdown: flush remaining spans before exit
process.on('SIGTERM', () => {
    sdk.shutdown()
        .then(() => console.log('OpenTelemetry SDK shut down successfully'))
        .catch((err) => console.error('Error shutting down OpenTelemetry SDK', err));
});

module.exports = sdk;
