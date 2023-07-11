function ChangeFocus 

import java.awt.Robot;
import java.awt.event.*;
SimKey=Robot;

% um zu commandwindow zu wechseln
SimKey.keyPress(java.awt.event.KeyEvent.VK_CONTROL);
SimKey.keyPress(java.awt.event.KeyEvent.VK_0);
SimKey.keyRelease(java.awt.event.KeyEvent.VK_CONTROL);
SimKey.keyRelease(java.awt.event.KeyEvent.VK_0);

WaitSecs(5);

% um von commandwindow zurückzuwechseln
SimKey.keyPress(java.awt.event.KeyEvent.VK_CONTROL);
SimKey.keyPress(java.awt.event.KeyEvent.VK_SHIFT);
SimKey.keyPress(java.awt.event.KeyEvent.VK_0);
SimKey.keyRelease(java.awt.event.KeyEvent.VK_CONTROL);
SimKey.keyRelease(java.awt.event.KeyEvent.VK_SHIFT);
SimKey.keyRelease(java.awt.event.KeyEvent.VK_0);