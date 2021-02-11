defmodule Wx do
  @moduledoc """
  Elixir version of the constants found in the wx.hrl file, reduced to what is needed in this sample only.
  """
  import Bitwise

  def wxID_ANY, do: -1

  def wxDEFAULT_FRAME_STYLE,
    do:
      wxSYSTEM_MENU()
      |> bor(
        wxRESIZE_BORDER()
        |> bor(
          wxMINIMIZE_BOX()
          |> bor(
            wxMAXIMIZE_BOX()
            |> bor(wxCLOSE_BOX() |> bor(wxCAPTION() |> bor(wxCLIP_CHILDREN())))
          )
        )
      )

  def wxRESIZE_BORDER, do: 64
  def wxTINY_CAPTION_VERT, do: 128
  def wxTINY_CAPTION_HORIZ, do: 256
  def wxMAXIMIZE_BOX, do: 512
  def wxMINIMIZE_BOX, do: 1024
  def wxSYSTEM_MENU, do: 2048
  def wxCLOSE_BOX, do: 4096
  def wxMAXIMIZE, do: 8192
  def wxMINIMIZE, do: wxICONIZE()
  def wxICONIZE, do: 16384
  def wxSTAY_ON_TOP, do: 32768
  def wxCLIP_CHILDREN, do: 4_194_304
  def wxCAPTION, do: 536_870_912
  def wxITEM_SEPARATOR, do: -1
  def wxITEM_NORMAL, do: 0
  def wxITEM_CHECK, do: 1
  def wxITEM_RADIO, do: 2
  def wxGROW, do: 8192
  def wxEXPAND, do: wxGROW()
  def wxICON_INFORMATION, do: 2048
  def wxHORIZONTAL, do: 4
end
