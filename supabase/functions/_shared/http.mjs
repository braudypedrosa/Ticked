export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function htmlResponse(body, status = 200) {
  const headers = new Headers(corsHeaders);
  headers.set("content-type", "text/html; charset=utf-8");
  headers.set("content-security-policy", "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'");
  headers.set("x-content-type-options", "nosniff");

  return new Response(body, {
    status,
    headers,
  });
}

export function textResponse(body, status = 200) {
  return new Response(body, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/plain; charset=utf-8",
    },
  });
}

export function redirectResponse(location, status = 302) {
  return new Response(null, {
    status,
    headers: {
      ...corsHeaders,
      Location: location,
    },
  });
}

export function oauthCallbackFallbackResponse(page, requestURL) {
  const host = new URL(requestURL).hostname;
  if (host.endsWith(".supabase.co")) {
    return textResponse(oauthCallbackText(page));
  }
  return htmlResponse(oauthCallbackPage(page));
}

export function oauthCallbackPage({
  tone = "success",
  title = "Connected",
  message = "You can close this window and return to Ticked.",
  detail = "",
} = {}) {
  const isSuccess = tone === "success";
  const icon = isSuccess ? "&#10003;" : "!";
  const safeTitle = escapeHTML(title);
  const safeMessage = escapeHTML(message);
  const safeDetail = escapeHTML(detail);

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>${safeTitle} | Ticked</title>
  <style>
    :root {
      color-scheme: light dark;
      --bg: #f4f7f3;
      --panel: rgba(255, 255, 255, 0.88);
      --text: #17201a;
      --muted: #5f6b62;
      --line: rgba(23, 32, 26, 0.12);
      --accent: ${isSuccess ? "#2f8f5b" : "#b84d44"};
      --accent-bg: ${isSuccess ? "#e1f4e9" : "#f9e5e2"};
      --shadow: 0 24px 70px rgba(31, 46, 35, 0.16);
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #151917;
        --panel: rgba(32, 38, 35, 0.9);
        --text: #eef4ef;
        --muted: #aab5ad;
        --line: rgba(238, 244, 239, 0.12);
        --accent-bg: ${isSuccess ? "#183726" : "#3b211e"};
        --shadow: 0 24px 70px rgba(0, 0, 0, 0.34);
      }
    }

    * {
      box-sizing: border-box;
    }

    body {
      min-height: 100vh;
      margin: 0;
      display: grid;
      place-items: center;
      padding: 32px;
      background:
        radial-gradient(circle at top left, color-mix(in srgb, var(--accent) 18%, transparent), transparent 34rem),
        linear-gradient(135deg, var(--bg), color-mix(in srgb, var(--bg) 92%, var(--accent)));
      color: var(--text);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
    }

    main {
      width: min(100%, 520px);
      padding: 34px;
      border: 1px solid var(--line);
      border-radius: 18px;
      background: var(--panel);
      box-shadow: var(--shadow);
      text-align: center;
      backdrop-filter: blur(18px);
    }

    .mark {
      width: 58px;
      height: 58px;
      display: inline-grid;
      place-items: center;
      margin-bottom: 22px;
      border-radius: 16px;
      background: var(--accent-bg);
      color: var(--accent);
      font-size: 30px;
      font-weight: 800;
    }

    h1 {
      margin: 0;
      font-size: clamp(28px, 6vw, 42px);
      line-height: 1.05;
      letter-spacing: 0;
    }

    p {
      margin: 14px 0 0;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.55;
    }

    .detail {
      margin-top: 18px;
      padding: 12px 14px;
      border: 1px solid var(--line);
      border-radius: 10px;
      background: color-mix(in srgb, var(--panel) 84%, var(--accent-bg));
      overflow-wrap: anywhere;
      text-align: left;
      font-size: 13px;
    }

    button {
      margin-top: 26px;
      min-height: 38px;
      padding: 0 18px;
      border: 0;
      border-radius: 9px;
      background: var(--accent);
      color: white;
      font: inherit;
      font-weight: 700;
      cursor: pointer;
    }

    button:hover {
      filter: brightness(1.05);
    }
  </style>
</head>
<body>
  <main>
    <div class="mark" aria-hidden="true">${icon}</div>
    <h1>${safeTitle}</h1>
    <p>${safeMessage}</p>
    ${safeDetail ? `<p class="detail">${safeDetail}</p>` : ""}
    <button type="button" onclick="window.close()">Close Window</button>
  </main>
</body>
</html>`;
}

export function oauthCallbackText({
  title = "Connected",
  message = "You can close this window and return to Ticked.",
  detail = "",
} = {}) {
  return [
    "Ticked",
    "",
    title,
    "",
    message,
    detail ? "" : null,
    detail || null,
  ]
    .filter((line) => line !== null)
    .join("\n");
}

export function optionsResponse() {
  return new Response("ok", { headers: corsHeaders });
}

export async function requestJSON(req) {
  try {
    return await req.json();
  } catch {
    return {};
  }
}

function escapeHTML(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
