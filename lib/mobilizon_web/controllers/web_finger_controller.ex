# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/web_finger/web_finger_controller.ex

defmodule MobilizonWeb.WebFingerController do
  use MobilizonWeb, :controller

  alias Mobilizon.Service.WebFinger

  def host_meta(conn, _params) do
    xml = WebFinger.host_meta()

    conn
    |> put_resp_content_type("application/xrd+xml")
    |> send_resp(200, xml)
  end

  def webfinger(conn, %{"resource" => resource}) do
    with {:ok, response} <- WebFinger.webfinger(resource, "JSON") do
      json(conn, response)
    else
      _e -> send_resp(conn, 404, "Couldn't find user")
    end
  end

  def webfinger(conn, _) do
    send_resp(conn, 400, "No query provided")
  end
end
