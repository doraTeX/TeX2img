#!/bin/sh
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size "in put.pdf" ./1/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./2/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "in put.pdf" ./3/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./4/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --transparent --with-text --delete-display-size "in put.pdf" ./5/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./6/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "in put.pdf" ./7/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./8/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size "in put.pdf" ./9/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./10/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "in put.pdf" ./11/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./12/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --transparent --no-with-text  --delete-display-size "in put.pdf" ./13/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./14/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "in put.pdf" ./15/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./16/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size "in put.pdf" ./17/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./18/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "in put.pdf" ./19/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "in put.pdf" ./20/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size "in put.pdf" ./21/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./22/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "in put.pdf" ./23/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "in put.pdf" ./24/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --delete-display-size "in put.pdf" ./25/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --delete-display-size "in put.pdf" ./26/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --delete-display-size "in put.pdf" ./27/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --delete-display-size "in put.pdf" ./28/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --transparent --no-plain-text "in put.pdf" ./29/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC --no-plain-text "in put.pdf" ./30/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --transparent --no-plain-text "in put.pdf" ./31/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC --no-plain-text "in put.pdf" ./32/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --transparent --plain-text "in put.pdf" ./33/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC --plain-text "in put.pdf" ./34/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --transparent --plain-text "in put.pdf" ./35/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC --plain-text "in put.pdf" ./36/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --transparent "in put.pdf" ./37/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC "in put.pdf" ./38/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --transparent "in put.pdf" ./39/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC "in put.pdf" ./40/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --transparent "in put.pdf" ./41/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC "in put.pdf" ./42/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --transparent "in put.pdf" ./43/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC "in put.pdf" ./44/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current "in put.pdf" ./45/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC "in put.pdf" ./46/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp "in put.pdf" ./47/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC "in put.pdf" ./48/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current "in put.pdf" ./49/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --background-color CCFFCC "in put.pdf" ./50/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp "in put.pdf" ./51/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --margins 10 --unit bp --background-color CCFFCC "in put.pdf" ./52/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --no-quick "in put.pdf" ./53/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick "in put.pdf" ./54/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick "in put.pdf" ./55/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "in put.pdf" ./56/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --transparent --no-quick "in put.pdf" ./57/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --background-color CCFFCC --no-quick "in put.pdf" ./58/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-quick "in put.pdf" ./59/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "in put.pdf" ./60/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --no-quick "in put.pdf" ./61/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick "in put.pdf" ./62/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick "in put.pdf" ./63/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "in put.pdf" ./64/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --no-quick "in put.pdf" ./65/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --no-quick "in put.pdf" ./66/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --no-quick "in put.pdf" ./67/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --no-quick "in put.pdf" ./68/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --quick "in put.pdf" ./69/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --quick "in put.pdf" ./70/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick "in put.pdf" ./71/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "in put.pdf" ./72/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --transparent --quick "in put.pdf" ./73/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --background-color CCFFCC --quick "in put.pdf" ./74/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --transparent --quick "in put.pdf" ./75/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "in put.pdf" ./76/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --transparent --quick "in put.pdf" ./77/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --background-color CCFFCC --quick "in put.pdf" ./78/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick "in put.pdf" ./79/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "in put.pdf" ./80/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --quick "in put.pdf" ./81/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --quick "in put.pdf" ./82/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --quick "in put.pdf" ./83/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --resolution 6 --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --quick "in put.pdf" ./84/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
