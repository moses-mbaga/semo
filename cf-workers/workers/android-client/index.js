import crypto from "crypto";

function extractBearer(req) {
  const raw = (req.headers.get("Authorization") || "").trim();
  if (!raw) return null;
  const parts = raw.split(/\s+/);
  const idx = parts.findIndex((p) => p.toLowerCase() === "bearer");
  if (idx === -1) return null;
  const token = parts.slice(idx + 1).join(" ");
  const cleaned = token.replace(/^\s*"|"\s*$/g, "").trim();
  return cleaned || null;
}

/**
 * Generates random client info and user agent for request obfuscation
 */
function generateRandomClientInfo() {
  // Authentic Android versions and devices
  const androidVersions = [
    { version: "9", build: "PQ3A.190605.03081104" },
    { version: "10", build: "QP1A.191005.007.A3" },
    { version: "11", build: "RP1A.200720.011" },
    { version: "12", build: "S1B.220414.015" },
    { version: "13", build: "TQ2A.230405.003" },
  ];

  // Real Redmi device models
  const redmiDevices = [
    { model: "23078RKD5C", brand: "Redmi" },
    { model: "2201117TY", brand: "Redmi" },
    { model: "2201117TG", brand: "Redmi" },
    { model: "22101316G", brand: "Redmi" },
    { model: "21121210G", brand: "Redmi" },
    { model: "M2012K11AG", brand: "Redmi" },
    { model: "M2007J20CG", brand: "Redmi" },
  ];

  // Real GAIDs (Google Advertising IDs) - these are example formats
  const gaids = [
    "c65f05f7-dd57-4d5e-8089-f99714d246cd",
    "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "f8e7d6c5-b4a3-9281-7065-432109876543",
    "12345678-90ab-cdef-1234-567890abcdef",
    "abcdef12-3456-7890-abcd-ef1234567890",
  ];

  // Device IDs (MD5 hashes of device info)
  const deviceIds = [
    "58bb277ebefaeb20f46dca639f173bc6",
    "a1b2c3d4e5f6789012345678901234ab",
    "f8e7d6c5b4a39281706543210987654c",
    "123456789012345678901234567890ab",
    "abcdef123456789012345678901234cd",
  ];

  // Version codes (incremental)
  const versionCodes = [50020042, 50020043, 50020044, 50020045, 50020046];

  // Network types for variety
  const networkTypes = ["NETWORK_WIFI", "NETWORK_MOBILE"];

  // Timezones for variety
  const timezones = [
    "Asia/Kolkata",
    "Asia/Shanghai",
    "Asia/Tokyo",
    "America/New_York",
    "Europe/London",
  ];

  // Generate fresh random IDs for each request
  const generateRandomGAID = () => {
    const chars = "0123456789abcdef";
    const sections = [8, 4, 4, 4, 12];
    return sections
      .map((length) => {
        let result = "";
        for (let i = 0; i < length; i++) {
          result += chars[Math.floor(Math.random() * chars.length)];
        }
        return result;
      })
      .join("-");
  };

  const generateRandomDeviceId = () => {
    const chars = "0123456789abcdef";
    let result = "";
    for (let i = 0; i < 32; i++) {
      result += chars[Math.floor(Math.random() * chars.length)];
    }
    return result;
  };

  // Select random values
  const randomAndroid =
    androidVersions[Math.floor(Math.random() * androidVersions.length)];
  const randomDevice =
    redmiDevices[Math.floor(Math.random() * redmiDevices.length)];
  const randomGaid =
    Math.random() > 0.5
      ? gaids[Math.floor(Math.random() * gaids.length)]
      : generateRandomGAID();
  const randomDeviceId =
    Math.random() > 0.5
      ? deviceIds[Math.floor(Math.random() * deviceIds.length)]
      : generateRandomDeviceId();
  const randomVersionCode =
    versionCodes[Math.floor(Math.random() * versionCodes.length)];
  const randomNetwork =
    networkTypes[Math.floor(Math.random() * networkTypes.length)];
  const randomTimezone =
    timezones[Math.floor(Math.random() * timezones.length)];

  // Generate user agent
  const userAgent = `com.community.oneroom/${randomVersionCode} (Linux; U; Android ${randomAndroid.version}; en_US; ${randomDevice.model}; Build/${randomAndroid.build}; Cronet/135.0.7012.3)`;

  // Generate client info
  const clientInfo = {
    package_name: "com.community.oneroom",
    version_name: "3.0.03.0529.03",
    version_code: randomVersionCode,
    os: "android",
    os_version: randomAndroid.version,
    install_ch: "ps",
    device_id: randomDeviceId,
    install_store: "ps",
    gaid: randomGaid,
    brand: randomDevice.brand,
    model: randomDevice.model,
    system_language: "en",
    net: randomNetwork,
    region: "US",
    timezone: randomTimezone,
    sp_code: "40401",
    "X-Play-Mode": "2",
  };

  return {
    userAgent,
    clientInfo: JSON.stringify(clientInfo),
  };
}

/**
 * Generates the x-tr-signature token based on the Android app's algorithm
 */
function generateXTrSignature(url, requestBody = "", options = {}) {
  const {
    method = "POST",
    contentType = "application/json; charset=utf-8",
    timeOffset = 0,
    useAlternateKey = false,
  } = options;

  // Signing keys from the Android code
  const signingKeys = {
    primary: "76iRl07s0xSN9jqmEWAt79EBJZulIQIsV64FZr2O",
    alternate: "Xqn2nnO41/L92o1iuXhSLHTbXvY4Z5ZZ62m8mSLA",
  };

  const signingKey = useAlternateKey
    ? signingKeys.alternate
    : signingKeys.primary;
  const timestamp = Date.now() + timeOffset;

  // Process request body
  let bodyHash = "";
  let contentLength = 0;

  if (requestBody && requestBody.length > 0) {
    let processedBody = requestBody;
    if (Buffer.byteLength(processedBody, "utf8") > 102400) {
      processedBody = processedBody.substring(0, 102400);
    }

    // Calculate MD5 hash of the body
    bodyHash = crypto
      .createHash("md5")
      .update(processedBody, "utf8")
      .digest("hex");
    contentLength = Buffer.byteLength(processedBody, "utf8");
  }

  // Process URL to get path and sorted query parameters
  const urlObj = new URL(url);
  let urlPath = urlObj.pathname;

  if (urlObj.search) {
    const params = new URLSearchParams(urlObj.search);
    const sortedParams = [];

    for (const [key, value] of params.entries()) {
      if (key !== "") {
        sortedParams.push({
          key: decodeURIComponent(key),
          value: decodeURIComponent(value),
        });
      }
    }

    sortedParams.sort((a, b) => a.key.localeCompare(b.key));

    if (sortedParams.length > 0) {
      const queryString = sortedParams
        .map((p) => `${p.key}=${p.value}`)
        .join("&");
      urlPath += `?${queryString}`;
    }
  }

  // Construct the string to be signed
  const stringToSign = [
    method.toUpperCase(),
    "",
    contentType || "",
    contentLength > 0 ? contentLength.toString() : "",
    timestamp.toString(),
    bodyHash,
    urlPath,
  ].join("\n");

  // Generate HMAC-MD5 signature
  const key = Buffer.from(signingKey, "base64");
  const hmac = crypto.createHmac("md5", key);
  hmac.update(stringToSign, "utf8");
  const signature = hmac.digest("base64");

  return `${timestamp}|2|${signature}`;
}

/**
 * Makes authenticated request to the API
 */
async function makeAuthenticatedRequest(url, options = {}) {
  const {
    method = "POST",
    body = null,
    headers = {},
    authorization = undefined,
  } = options;

  const bodyString = body ? JSON.stringify(body) : "";
  const contentType = "application/json; charset=utf-8";

  // Generate signature
  const signature = generateXTrSignature(url, bodyString, {
    method,
    contentType,
  });

  const { userAgent, clientInfo } = generateRandomClientInfo();

  const requestHeaders = {
    "Accept-Encoding": "gzip, deflate, br",
    Connection: "keep-alive",
    "Content-Type": contentType,
    "User-Agent": userAgent,
    "X-Client-Info": clientInfo,
    "X-Client-Status": "1",
    "X-Play-Mode": "2",
    "x-tr-signature": signature,
    ...headers,
  };

  if (authorization) {
    requestHeaders["Authorization"] = authorization;
  }

  if (bodyString) {
    requestHeaders["Content-Length"] = Buffer.byteLength(bodyString, "utf8");
  }

  const response = await fetch(url, {
    method,
    headers: requestHeaders,
    body: bodyString || undefined,
  });

  return response;
}

async function handleRequest(request, env) {
  // Enable CORS
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  // Handle preflight requests
  if (request.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(request.url);
    // AuthN: require Authorization: Bearer <CF_WORKERS_API_KEY>
    const apiKey = env?.CF_WORKERS_API_KEY;
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "Server missing API key" }), {
        status: 500,
        headers: corsHeaders,
      });
    }
    const provided = extractBearer(request);
    if (!provided) {
      return new Response(JSON.stringify({ error: "Missing Authorization" }), {
        status: 401,
        headers: corsHeaders,
      });
    }
    if (provided !== apiKey) {
      return new Response(JSON.stringify({ error: "Invalid API key" }), {
        status: 401,
        headers: corsHeaders,
      });
    }

    // Parse request parameters
    let requestData;
    if (request.method === "POST") {
      requestData = await request.json();
    } else {
      // For GET requests, use query parameters
      requestData = {
        url: url.searchParams.get("url"),
        method: url.searchParams.get("method") || "GET",
        body: url.searchParams.get("body")
          ? JSON.parse(url.searchParams.get("body"))
          : null,
        authorization: url.searchParams.get("authorization"),
      };
    }

    const {
      url: targetUrl,
      method = "POST",
      body,
      authorization,
    } = requestData;

    if (!targetUrl) {
      return new Response(
        JSON.stringify({ error: "URL parameter is required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    // Make the authenticated request
    const response = await makeAuthenticatedRequest(targetUrl, {
      method,
      body,
      authorization,
    });

    const responseData = await response.text();

    return new Response(responseData, {
      status: response.status,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Request failed",
        message: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
}

export default {
  fetch: handleRequest,
};
