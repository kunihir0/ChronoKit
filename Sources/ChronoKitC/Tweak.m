#import <Orion/Orion.h>
#import <os/log.h>

os_log_t ck_log;

__attribute__((constructor)) static void init() {
    // Initialize Orion - do not remove this line.
    orion_init();
    ck_log = os_log_create("com.kunihir0.chronokit", "ChronoKit");
    // Custom initialization code goes here.
}
