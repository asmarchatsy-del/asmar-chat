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

    const roomQuery = await fetch(
      `${supabaseUrl}/rest/v1/rooms?select=id&livekit_room_name=eq.${encodeURIComponent(room)}&is_active=eq.true`,
      {
        headers: {
          Authorization: auth,
          apikey: supabaseAnonKey,
        },
      },
    );
    if (!roomQuery.ok) {
      return Response.json({ error: "Unable to verify room" }, { status: 502 });
    }
    const rooms = await roomQuery.json();
    if (!Array.isArray(rooms) || rooms.length !== 1) {
      return Response.json({ error: "Room not found" }, { status: 404 });
    }

    const memberQuery = await fetch(
      `${supabaseUrl}/rest/v1/room_members?select=room_id&user_id=eq.${identity}&left_at=is.null`,
      {
        headers: {
          Authorization: auth,
          apikey: supabaseAnonKey,
        },
      },
    );
    if (!memberQuery.ok) {
      return Response.json({ error: "Unable to verify membership" }, { status: 502 });
    }
    const members = await memberQuery.json();
    if (!Array.isArray(members) || members.length === 0) {
      return Response.json({ error: "Join the room before requesting audio access" }, { status: 403 });
    }

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
