#include <stdio.h>
#include <syslog.h>
#include <string.h>

int main(int argc, char *argv[])
{
    if(argc < 3)
    {
        openlog("Logging errors", LOG_PID, LOG_USER);
        syslog(LOG_ERR, "Invalid number of arguments:%d, when there are 2 expected", argc - 1);
        closelog();   
        return 1;    
    }

    FILE* destFile = fopen(argv[1], "wb");
    
    if(destFile == NULL)
    {
        openlog("Logging errors", LOG_PID, LOG_USER);
        syslog(LOG_ERR, "Could not find destination file");
        closelog();   
        return 1;    
    }

    fwrite(argv[2], 1, strlen(argv[2]), destFile);
    
    openlog("Logging success", LOG_PID, LOG_USER);
    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
    closelog();

    fclose(destFile);

    return 0;
}
