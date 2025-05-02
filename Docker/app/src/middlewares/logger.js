const { v4: generateUuid } = require('uuid');
const { format, createLogger, transports } = require('winston');

const dotenv = require('dotenv');

dotenv.config({ path: './src/.env' });

module.exports = {
    info,
    warn,
    error,
    manejarError,
    generarTraceId,
};

const serviceContext = {
    service: require('../../package.json').name,
    version: require('../../package.json').version
};

const logger = createLogger({
    level: 'info',
    format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.errors({ stack: true }),
        format.splat(),
        format.json()
    ),
    defaultMeta: { ApplicationName: serviceContext.service },
    transports: [
        new transports.Console(),
    ],
});

function info(message, traceId, context) {
    logger.info({
        level: 'INFO',
        message: serviceContext.service + ' - ' + formatMessage(message),
        serviceContext,
        traceId,
        context: context ?
            context instanceof Error ? context.toJSON() : context
            : '',
    });
}

function warn(message, traceId, context) {
    logger.warn({
        level: 'WARN',
        message: serviceContext.service + ' - ' + formatMessage(message),
        serviceContext,
        traceId,
        context: context ?
            context instanceof Error ? context.toJSON() : context
            : '',
    });
}

function error(message, traceId, context) {
    logger.error({
        level: 'ERROR',
        message: serviceContext.service + ' - ' + formatMessage(message),
        serviceContext,
        traceId,
        context: context ?
            context instanceof Error ? context.toJSON() : context
            : '',
    });
}

function formatMessage(message) {
    if (message instanceof Error) {
        return message.stack;
    }
    if (typeof message === "string") {
        return message;
    }
    if (typeof message === "object") {
        try {
            return JSON.stringify(message);
        } catch (e) {
            return message.toString();
        }
    }
    return message;
}

function manejarError(err, req, res) {
    if (err instanceof SyntaxError) { return res.sendStatus(400); }

    res.status(500).send("Ocurrió un error inesperado");

    error(err, req.traceId, {
        httpRequest: {
            status: res.statusCode,
            requestUrl: req.url,
            requestMethod: req.method,
            userAgent: req.headers["user-agent"],
            latencyMillis: parseInt(res.locals.responseTime),
            protocol: req.protocol,
            apiversion: getAPIVeresionFromUrl(req.url)
        },
        usuario: req.usuario ? req.usuario.id : undefined
    });
}


function generarTraceId(req, res, next) {
    req.traceId = generateUuid();
    next();
}

function getAPIVeresionFromUrl(url) {
    const regexVersion = /\/v(\d+)\//;
    const result = regexVersion.exec(url);
    return result && result.length ? result[1] : "";
}
