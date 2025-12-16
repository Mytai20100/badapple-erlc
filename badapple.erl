-module(video_ascii).
-export([main/1]).

-define(ASCII_CHARS, " .:-=+*#%@").
-define(WIDTH, 80).
-define(HEIGHT, 40).

download_video(Url) ->
    io:format("Downloading video...~n"),
    os:cmd("yt-dlp -f worst -o video.mp4 '" ++ Url ++ "'").

rgb_to_ascii(R, G, B) ->
    Brightness = (R + G + B) div 3,
    Index = Brightness * (length(?ASCII_CHARS) - 1) div 255,
    lists:nth(Index + 1, ?ASCII_CHARS).

extract_and_display_frame(Time) ->
    Cmd = io_lib:format("ffmpeg -ss ~.2f -i video.mp4 -vframes 1 -vf scale=~p:~p -f rawvideo -pix_fmt rgb24 - 2>/dev/null",
                        [Time, ?WIDTH, ?HEIGHT]),
    Pixels = os:cmd(lists:flatten(Cmd)),
    
    case Pixels of
        [] -> ok;
        _ ->
            io:format("~s", ["\033[2J\033[H"]),
            display_pixels(Pixels, 0, 0)
    end.

display_pixels(_, ?HEIGHT, _) -> ok;
display_pixels(Pixels, Y, ?WIDTH) ->
    io:format("~n"),
    display_pixels(Pixels, Y + 1, 0);
display_pixels(Pixels, Y, X) ->
    Idx = (Y * ?WIDTH + X) * 3 + 1,
    case Idx + 2 =< length(Pixels) of
        true ->
            R = lists:nth(Idx, Pixels),
            G = lists:nth(Idx + 1, Pixels),
            B = lists:nth(Idx + 2, Pixels),
            io:format("~c", [rgb_to_ascii(R, G, B)]);
        false -> ok
    end,
    display_pixels(Pixels, Y, X + 1).

main([]) -> main(["https://youtu.be/FtutLA63Cp8"]);
main([Url]) ->
    download_video(Url),
    play_video(0.0, 30.0, 10.0).

play_video(Time, Duration, _Fps) when Time >= Duration -> ok;
play_video(Time, Duration, Fps) ->
    extract_and_display_frame(Time),
    timer:sleep(round(1000 / Fps)),
    play_video(Time + 1.0 / Fps, Duration, Fps).
