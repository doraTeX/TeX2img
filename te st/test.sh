#!/bin/sh
./tex2img --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size "sam ple.tex" ./1/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./2/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "sam ple.tex" ./3/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./4/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --with-text --delete-display-size "sam ple.tex" ./5/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./6/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "sam ple.tex" ./7/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./8/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size "sam ple.tex" ./9/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./10/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "sam ple.tex" ./11/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./12/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --no-with-text  --delete-display-size "sam ple.tex" ./13/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./14/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "sam ple.tex" ./15/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./16/"sam ple".pdf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --with-text --delete-display-size "sam ple.tex" ./17/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./18/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --with-text --delete-display-size "sam ple.tex" ./19/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --with-text --delete-display-size "sam ple.tex" ./20/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-with-text  --delete-display-size "sam ple.tex" ./21/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./22/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-with-text  --delete-display-size "sam ple.tex" ./23/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-with-text  --delete-display-size "sam ple.tex" ./24/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --delete-display-size "sam ple.tex" ./25/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --delete-display-size "sam ple.tex" ./26/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --delete-display-size "sam ple.tex" ./27/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --delete-display-size "sam ple.tex" ./28/"sam ple".svg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent --no-plain-text "sam ple.tex" ./29/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC --no-plain-text "sam ple.tex" ./30/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent --no-plain-text "sam ple.tex" ./31/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC --no-plain-text "sam ple.tex" ./32/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent --plain-text "sam ple.tex" ./33/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC --plain-text "sam ple.tex" ./34/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent --plain-text "sam ple.tex" ./35/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC --plain-text "sam ple.tex" ./36/"sam ple".eps; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent "sam ple.tex" ./37/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC "sam ple.tex" ./38/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent "sam ple.tex" ./39/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC "sam ple.tex" ./40/"sam ple".emf; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --transparent "sam ple.tex" ./41/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC "sam ple.tex" ./42/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --transparent "sam ple.tex" ./43/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC "sam ple.tex" ./44/"sam ple".png; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current "sam ple.tex" ./45/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC "sam ple.tex" ./46/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp "sam ple.tex" ./47/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC "sam ple.tex" ./48/"sam ple".jpg; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current "sam ple.tex" ./49/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --background-color CCFFCC "sam ple.tex" ./50/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp "sam ple.tex" ./51/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --margins 10 --unit bp --background-color CCFFCC "sam ple.tex" ./52/"sam ple".bmp; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-quick "sam ple.tex" ./53/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick "sam ple.tex" ./54/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick "sam ple.tex" ./55/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "sam ple.tex" ./56/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --no-quick "sam ple.tex" ./57/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --no-quick "sam ple.tex" ./58/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --no-quick "sam ple.tex" ./59/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "sam ple.tex" ./60/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --no-quick "sam ple.tex" ./61/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --no-quick "sam ple.tex" ./62/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --no-quick "sam ple.tex" ./63/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --no-quick "sam ple.tex" ./64/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --no-quick "sam ple.tex" ./65/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --no-quick "sam ple.tex" ./66/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --no-quick "sam ple.tex" ./67/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --no-quick "sam ple.tex" ./68/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --quick "sam ple.tex" ./69/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --quick "sam ple.tex" ./70/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick "sam ple.tex" ./71/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "sam ple.tex" ./72/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --transparent --quick "sam ple.tex" ./73/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --background-color CCFFCC --quick "sam ple.tex" ./74/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --transparent --quick "sam ple.tex" ./75/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "sam ple.tex" ./76/"sam ple".tiff; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --transparent --quick "sam ple.tex" ./77/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --background-color CCFFCC --quick "sam ple.tex" ./78/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --transparent --quick "sam ple.tex" ./79/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --no-merge-output-files --margins 10 --unit bp --background-color CCFFCC --quick "sam ple.tex" ./80/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --transparent --quick "sam ple.tex" ./81/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --background-color CCFFCC --quick "sam ple.tex" ./82/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --transparent --quick "sam ple.tex" ./83/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
./tex2img --workingdir current --merge-output-files --animation-delay 0.5 --animation-loop 0 --margins 10 --unit bp --background-color CCFFCC --quick "sam ple.tex" ./84/"sam ple".gif; if [ $? -ne 0 ]; then echo "ERROR!"; exit 1; fi
