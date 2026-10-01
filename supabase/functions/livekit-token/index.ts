import { AccessToken } from "npm:livekit-server-sdk@2.15.3";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  try {
    const auth = req.headers.get("Authorization");
    if (!auth) return Response.json({ error: "Unauthorized" }, { status: 401 });

    const body = await req.json();
    const room = String(body.room ?? "").trim();
    if (!room) return Response.json({ error: "room is required" }, { status: 400 });

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const livekitUrl = Deno.env.get("LIVEKIT_URL");
    const livekitApiKey = Deno.env.get("LIVEKIT_API_KEY");
    const livekitApiSecret = Deno.env.get("LIVEKIT_API_SECRET");

    if (!supabaseUrl || !supabaseAnonKey || !livekitUrl || !livekitApiKey || !livekitApiSecret) {
      return Response.json({ error: "LiveKit server configuration is missing" }, { status: 500 });
    }

    const verify = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { Authorization: auth, apikey: supabaseAnonKey },
    });
    if (!verify.ok) return Response.json({ error: "Invalid session" }, { status: 401 });

    const user = await verify.json();
    const identity = String(user.id);
    const token = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity,
      name: user.user_metadata?.display_name ?? user.email ?? identity,
      ttl: "2h",
    });
    token.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true });

    return Response.json({ token: await token.toJwt(), url: livekitUrl });
  } catch (error) {
    return Response.json({ error: String(error) }, { status: 500 });
  }
});
